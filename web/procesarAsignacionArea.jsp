<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.List, clasesGenericas.Usuario, clasesGenericas.Area" %>
<%@ page import="java.sql.SQLException" %>
<%
    try {
        List<Usuario> usuarios = Usuario.findAll();

        for (Usuario u : usuarios) {
            String paramName = "area_" + u.getId();
            String valorArea  = request.getParameter(paramName);
            Integer nuevaArea = null;

            if (valorArea != null && !valorArea.trim().isEmpty()) {
                nuevaArea = Integer.valueOf(valorArea);
            }

            if ((u.getIdArea() == null && nuevaArea != null)
             || (u.getIdArea() != null && !u.getIdArea().equals(nuevaArea))) {
                u.setIdArea(nuevaArea);
                u.saveOrUpdate();
            }
        }

        response.sendRedirect("asignarArea.jsp?msg=ok");
        return;

    } catch (SQLException ex) {
        ex.printStackTrace();
        out.println("<h3>Error al guardar asignaciones: " + ex.getMessage() + "</h3>");
    }
%>
