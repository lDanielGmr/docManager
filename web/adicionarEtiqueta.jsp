<%@ page import="clasesGenericas.Etiqueta" %>
<%
    request.setCharacterEncoding("UTF-8");
    String nombre = request.getParameter("nombre");

    Etiqueta etq = new Etiqueta();
    etq.setNombre(nombre);
    
    if (etq.save()) {
        response.sendRedirect("etiqueta.jsp");
    } else {
        out.println("<script>alert('Error al guardar la etiqueta'); history.back();</script>");
    }
%>
