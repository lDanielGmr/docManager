<%@ page import="clasesGenericas.Area" %>
<%@ page import="java.sql.SQLIntegrityConstraintViolationException" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
    String idStr  = request.getParameter("id");
    String nombre = request.getParameter("nombre");
    boolean esUpdate = (idStr != null && !idStr.trim().isEmpty());

    if (nombre != null) {
        nombre = nombre.trim();
        try {
            if (esUpdate) {
                int id = Integer.parseInt(idStr);
                Area a = Area.findById(id);
                if (a != null) {
                    a.setNombre(nombre);
                    a.update();
                }
            } else {
                Area a = new Area();
                a.setNombre(nombre);
                a.save();
            }
            response.sendRedirect("area.jsp");
            return;
        } catch (SQLIntegrityConstraintViolationException dup) {
            out.println("<script>");
            out.println("  alert('Ya existe un área con ese nombre.');");
            out.println("  window.location = 'area.jsp';");
            out.println("</script>");
            return;
        } catch (Exception e) {
        }
    }
    response.sendRedirect("area.jsp");
%>
