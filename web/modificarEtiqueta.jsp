<%@ page import="clasesGenericas.Etiqueta" %>
<%
    request.setCharacterEncoding("UTF-8");
    int id = Integer.parseInt(request.getParameter("id"));
    String nombre = request.getParameter("nombre");

    Etiqueta etq = Etiqueta.findById(id);
    if (etq != null) {
        etq.setNombre(nombre);
        if (etq.update()) {
            response.sendRedirect("etiqueta.jsp");
        } else {
            out.println("<script>alert('Error al modificar la etiqueta'); history.back();</script>");
        }
    } else {
        out.println("<script>alert('Etiqueta no encontrada'); history.back();</script>");
    }
%>
