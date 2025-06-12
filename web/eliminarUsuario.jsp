<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Usuario" %>
<%@ include file="menu.jsp" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Eliminar Usuario</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

</head>
<body>
<%
  String idStr = request.getParameter("id");
  if (idStr==null) { response.sendRedirect("usuario.jsp"); return; }
  int id = Integer.parseInt(idStr);
  Usuario u = new Usuario();
  u.setId(id);

  if ("POST".equalsIgnoreCase(request.getMethod())) {
    u.delete();
    response.sendRedirect("usuario.jsp");
    return;
  }
%>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Eliminar Usuario #<%=id%></h2>
      <p>¿Estás seguro de que deseas eliminar este usuario?</p>
      <form method="post" action="eliminarUsuarios.jsp?id=<%=id%>">
        <div class="actions">
          <button type="submit" class="btn-guardar">Sí, eliminar</button>
          <button type="button" class="btn-cancelar" onclick="location.href='usuario.jsp'">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
