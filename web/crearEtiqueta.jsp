<%@page import="java.io.PrintWriter"%>
<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="
    java.io.PrintWriter,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet
" %>
<%@ page import="clasesGenericas.Etiqueta, ConexionBD.conexionBD" %>
<%
    String nombre = request.getParameter("nombre");
    response.setCharacterEncoding("UTF-8");
    try (PrintWriter out = response.getWriter();
         Connection conn = conexionBD.conectar()) {

        String sql = "INSERT INTO etiqueta(nombre) VALUES(?)";
        int newId;
        try (PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (!rs.next()) throw new RuntimeException("No se obtuvo ID");
                newId = rs.getInt(1);
            }
        }
        out.print("{\"id\":" + newId + ",\"nombre\":\"" + nombre.replace("\"","\\\"") + "\"}");
    } catch (Exception e) {
        response.setStatus(500);
        response.getWriter().print("{\"error\":\"" + e.getMessage().replace("\"","\\\"") + "\"}");
    }
%>
