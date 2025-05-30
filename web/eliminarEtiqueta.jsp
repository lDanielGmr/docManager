<%@ page import="clasesGenericas.Etiqueta" %>
<%
    int id = Integer.parseInt(request.getParameter("id"));
    Etiqueta etq = Etiqueta.findById(id);
    
    if (etq != null && etq.delete()) {
        response.sendRedirect("etiqueta.jsp");
    } else {
        out.println("<script>alert('Error al eliminar la etiqueta'); history.back();</script>");
    }
%>
