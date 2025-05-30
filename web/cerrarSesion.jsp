<%@ page language="java" contentType="text/html; charset=UTF-8" session="true" %>
<%
    session.invalidate();
    response.sendRedirect("index.jsp");
%>
