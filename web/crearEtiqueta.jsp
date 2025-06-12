<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    clasesGenericas.Etiqueta,
    ConexionBD.conexionBD
" %>
<%
    String nombre = request.getParameter("nombre");
    response.setCharacterEncoding("UTF-8");

    if (nombre == null || nombre.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"error\":\"El parámetro 'nombre' es obligatorio\"}");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = conexionBD.conectar();
        String sql = "INSERT INTO etiqueta(nombre) VALUES(?)";
        ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
        ps.setString(1, nombre.trim());
        int affected = ps.executeUpdate();
        if (affected == 0) {
            throw new RuntimeException("No se pudo insertar la etiqueta");
        }
        rs = ps.getGeneratedKeys();
        if (rs.next()) {
            int newId = rs.getInt(1);
            out.print("{\"id\":" + newId + ",\"nombre\":\"" + nombre.replace("\"","\\\"") + "\"}");
        } else {
            throw new RuntimeException("No se obtuvo ID generado");
        }
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"error\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception ignore) {}
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
%>
