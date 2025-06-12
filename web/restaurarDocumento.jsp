<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.io.IOException,
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
    int userId    = usuarioSesion.getId();
    int userRolId = usuarioSesion.getRol().getId();

    boolean puedeRestaurar = false;
    try (Connection connPerm = conexionBD.conectar();
         PreparedStatement pstPerm = connPerm.prepareStatement(
             "SELECT 1 FROM rol_permiso rp JOIN permiso p ON rp.permiso_id=p.id " +
             "WHERE rp.rol_id=? AND p.nombre=?"
         )) {
        pstPerm.setInt(1, userRolId);
        pstPerm.setString(2, "restaurar_documento");
        try (ResultSet rsPerm = pstPerm.executeQuery()) {
            puedeRestaurar = rsPerm.next();
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    if (!puedeRestaurar) {
        response.sendRedirect("papelera.jsp?error=sin_permiso");
        return;
    }

    String idParam = request.getParameter("id");
    if (idParam == null) {
        response.sendRedirect("papelera.jsp?error=id_invalido");
        return;
    }
    int docId;
    try {
        docId = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("papelera.jsp?error=id_invalido");
        return;
    }

    boolean esPropio = false;
    try (Connection connCheck = conexionBD.conectar();
         PreparedStatement pstCheck = connCheck.prepareStatement(
             "SELECT 1 FROM documento WHERE id=? AND eliminado=1 AND (radicado_a=? OR recibido_por=?)"
         )) {
        pstCheck.setInt(1, docId);
        pstCheck.setInt(2, userId);
        pstCheck.setInt(3, userId);
        try (ResultSet rsCheck = pstCheck.executeQuery()) {
            esPropio = rsCheck.next();
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    if (!esPropio) {
        response.sendRedirect("papelera.jsp?error=no_autorizado");
        return;
    }

    try (Connection conn = conexionBD.conectar()) {
        conn.setAutoCommit(false);

        try (PreparedStatement pstUpd = conn.prepareStatement(
                "UPDATE documento SET eliminado=0 WHERE id=?"
            )) {
            pstUpd.setInt(1, docId);
            pstUpd.executeUpdate();
        }

        try (PreparedStatement pstDel = conn.prepareStatement(
                "DELETE FROM papelera WHERE doc_id=?"
            )) {
            pstDel.setInt(1, docId);
            pstDel.executeUpdate();
        }

        try (PreparedStatement pstAudit = conn.prepareStatement(
                "INSERT INTO audit_log(usuario_id, documento_id, accion) VALUES (?, ?, ?)"
            )) {
            pstAudit.setInt(1, userId);
            pstAudit.setInt(2, docId);
            pstAudit.setString(3, "RESTAURAR_DOCUMENTO_EN_PAPELERA");
            pstAudit.executeUpdate();
        }

        conn.commit();
    } catch (SQLException e) {
        e.printStackTrace();
        response.sendRedirect("papelera.jsp?error=error_restaurar");
        return;
    }

    response.sendRedirect("papelera.jsp?msg=restaurado");
%>
