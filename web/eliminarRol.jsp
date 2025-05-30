<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Rol, ConexionBD.conexionBD" %>
<%
    String idStr = request.getParameter("id");
    if (idStr != null) {
        try (java.sql.Connection cn = conexionBD.conectar()) {
            int id = Integer.parseInt(idStr);

            try (java.sql.PreparedStatement ps1 =
                     cn.prepareStatement("UPDATE usuario SET id_rol = NULL WHERE id_rol = ?")) {
                ps1.setInt(1, id);
                ps1.executeUpdate();
            }

            Rol r = Rol.findById(id);
            if (r != null) {
                r.delete();
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
    response.sendRedirect("rol.jsp");
%>
