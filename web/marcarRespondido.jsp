<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="ConexionBD.conexionBD" %>
<%
    String idStr = request.getParameter("id");

    if (idStr != null) {
        java.sql.Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = conexionBD.conectar();
            if (conn != null) {
                ps = conn.prepareStatement("UPDATE documento SET respondido = TRUE WHERE id = ?");
                ps.setInt(1, Integer.parseInt(idStr));
                int updated = ps.executeUpdate();
                response.setStatus(updated == 1 ? 200 : 500);
            } else {
                response.setStatus(500); 
            }
        } catch (Exception e) {
            e.printStackTrace(); 
            response.setStatus(500);
        } finally {
            if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    } else {
        response.setStatus(400); 
    }
%>
