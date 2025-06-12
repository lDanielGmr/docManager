<%@page import="ConexionBD.conexionBD"%>
<%@ page import="
    java.io.IOException,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.util.List,
    clasesGenericas.Version,
    clasesGenericas.Usuario,
    ConexionBD.conexionBD
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    int usuarioId = usuarioSesion.getId();

    String vidStr = request.getParameter("vid");
    if (vidStr == null) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Falta el parámetro vid");
        return;
    }

    int versionId;
    try {
        versionId = Integer.parseInt(vidStr);
    } catch (NumberFormatException e) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "vid inválido");
        return;
    }

    int documentoId = 0;
    try (Connection conn = conexionBD.conectar();
         PreparedStatement pst1 = conn.prepareStatement(
             "SELECT doc_id FROM version WHERE id = ?"
         )) {
        pst1.setInt(1, versionId);
        try (ResultSet rs = pst1.executeQuery()) {
            if (rs.next()) {
                documentoId = rs.getInt("doc_id");
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Versión no encontrada");
                return;
            }
        }

        try (PreparedStatement pst2 = conn.prepareStatement(
                "INSERT INTO audit_log(usuario_id, documento_id, accion) VALUES (?, ?, ?)"
        )) {
            pst2.setInt(1, usuarioId);
            pst2.setInt(2, documentoId);
            pst2.setString(3, "RESTAURAR_VERSION");  
            pst2.executeUpdate();
        }

    } catch (Exception e) {
        e.printStackTrace();
    }

    Version verSeleccionada = Version.findById(versionId);
    if (verSeleccionada == null) {
        response.sendError(HttpServletResponse.SC_NOT_FOUND, "Versión no encontrada");
        return;
    }

    int docId = verSeleccionada.getDocId();
    String ruta = verSeleccionada.getRuta();

    List<Version> versionesActuales = Version.findByDocId(docId);

    int maxNum = 0;
    for (Version v : versionesActuales) {
        if (v.getNumero() > maxNum) {
            maxNum = v.getNumero();
        }
    }
    int nuevoNumero = maxNum + 1;

    Version nuevaVersion = new Version();
    nuevaVersion.setDocId(docId);
    nuevaVersion.setNumero(nuevoNumero);
    nuevaVersion.setRuta(ruta);
    boolean guardado = nuevaVersion.save();

    if (!guardado) {
        response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error al guardar la nueva versión");
        return;
    }

    response.sendRedirect("versionDocumento.jsp?docId=" + docId);
%>
