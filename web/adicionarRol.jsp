<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Rol" %>
<%
    String nombre = request.getParameter("nombre");
    if (nombre != null && !nombre.trim().isEmpty()) {
        Rol r = new Rol();
        r.setNombre(nombre.trim());
        r.save();
    }
    response.sendRedirect("rol.jsp");
%>
