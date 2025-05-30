<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Rol" %>
<%
    String idStr = request.getParameter("id");
    String nombre = request.getParameter("nombre");
    if (idStr != null && nombre != null && !nombre.trim().isEmpty()) {
        try {
            int id = Integer.parseInt(idStr);
            Rol r = Rol.findById(id);
            if (r != null) {
                r.setNombre(nombre.trim());
                r.update();
            }
        } catch (NumberFormatException ignored) {}
    }
    response.sendRedirect("rol.jsp");
%>
