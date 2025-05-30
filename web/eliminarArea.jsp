<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Area" %>
<%
    int id = Integer.parseInt(request.getParameter("id"));
    Area a = new Area();
    a.setId(id);
    a.delete();
    response.sendRedirect("area.jsp");
%>
