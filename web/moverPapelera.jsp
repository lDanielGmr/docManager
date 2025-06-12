<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.io.PrintWriter,
    java.io.StringWriter,
    ConexionBD.conexionBD,
    clasesGenericas.Usuario
" %>
<%
    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String idParam = request.getParameter("id");
    if (idParam == null) {
        out.println("<p style='color:red;'>Falta parámetro id.</p>");
        return;
    }
    int docId;
    try {
        docId = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        out.println("<p style='color:red;'>ID inválido.</p>");
        return;
    }

    String nombreArchivo = "";
    boolean existeYNoElim = false;

    try (Connection conn = conexionBD.conectar()) {
        conn.setAutoCommit(false);

        String queryCheck =
            "SELECT d.eliminado, d.nombre_archivo " +
            "FROM documento d " +
            "WHERE d.id = ?";
        try (PreparedStatement psCheck = conn.prepareStatement(queryCheck)) {
            psCheck.setInt(1, docId);
            try (ResultSet rs = psCheck.executeQuery()) {
                if (rs.next()) {
                    boolean yaEliminado = rs.getBoolean("eliminado");
                    String tmp = rs.getString("nombre_archivo");
                    if (tmp != null) {
                        nombreArchivo = tmp;
                    } else {
                        nombreArchivo = "";
                    }
                    if (!yaEliminado) {
                        existeYNoElim = true;
                    }
                }
            }
        }

        if (!existeYNoElim) {
            conn.rollback();
            out.println("<p style='color:red;'>El documento no existe o ya está en papelera.</p>");
            return;
        }

        String sqlUpdate = "UPDATE documento SET eliminado = 1 WHERE id = ?";
        try (PreparedStatement psUpd = conn.prepareStatement(sqlUpdate)) {
            psUpd.setInt(1, docId);
            psUpd.executeUpdate();
        }

        
        String ubicOrigin = "/uploads/" + nombreArchivo;
        String sqlInsert =
            "INSERT INTO papelera (doc_id, ubic_origin) VALUES (?, ?)";
        try (PreparedStatement psIns = conn.prepareStatement(sqlInsert)) {
            psIns.setInt(1, docId);
            psIns.setString(2, ubicOrigin);
            psIns.executeUpdate();
        }

        conn.commit();
    } catch (SQLException sq) {
        out.println("<p style='color:red;'>Error SQL: " + sq.getMessage() + "</p>");
        return;
    } catch (Exception ex) {
        StringWriter sw = new StringWriter();
        ex.printStackTrace(new PrintWriter(sw));
        out.println("<pre style='color:red;'>" + sw.toString() + "</pre>");
        return;
    }

    response.sendRedirect("documento.jsp");
%>
