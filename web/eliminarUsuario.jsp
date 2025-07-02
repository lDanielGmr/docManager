<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Usuario" %>
<%@ include file="menu.jsp" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Eliminar Usuario</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: Arial, sans-serif;
      background: url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: #333333;
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    body::before {
      content: "";
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(0, 0, 0, 0.4);
      z-index: -1;
    }
    .container {
      width: 100%;
      max-width: 360px;
      background-color: rgba(255, 255, 255, 0.9);
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }
    .confirm-box h2 {
      font-size: 1.3rem;
      margin-bottom: 1rem;
      text-align: center;
      color: #222222;
    }
    .confirm-box p {
      font-size: 0.95rem;
      margin-bottom: 1.5rem;
      text-align: center;
      color: #555555;
    }
    .error-message {
      background-color: #f8d7da;
      color: #721c24;
      border: 1px solid #f5c6cb;
      padding: 10px;
      border-radius: 4px;
      margin-bottom: 1rem;
      text-align: center;
      font-size: 0.9rem;
    }
    .actions {
      display: flex;
      justify-content: center;
      gap: 10px;
      flex-wrap: wrap;
    }
    .actions .btn-yes,
    .actions .btn-cancel {
      padding: 0.5rem 1rem;
      font-size: 0.9rem;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .actions .btn-yes {
      background-color: #e74c3c;
      color: #ffffff;
    }
    .actions .btn-yes:hover {
      background-color: #c0392b;
    }
    .actions .btn-cancel {
      background-color: #bdc3c7;
      color: #2c3e50;
    }
    .actions .btn-cancel:hover {
      background-color: #95a5a6;
    }
    @media (max-width: 400px) {
      .container {
        padding: 15px;
      }
      .confirm-box h2 {
        font-size: 1.2rem;
      }
      .confirm-box p {
        font-size: 0.9rem;
      }
      .actions .btn-yes,
      .actions .btn-cancel {
        width: 100%;
        justify-content: center;
      }
    }
  </style>
</head>
<body>
<%
  if ("POST".equalsIgnoreCase(request.getMethod())) {
      response.sendRedirect(request.getContextPath() + "/usuario.jsp");
      return;
  }

  String idStr = request.getParameter("id");
  if (idStr == null) {
    response.sendRedirect(request.getContextPath() + "/usuario.jsp");
    return;
  }
  int id = -1;
  try {
    id = Integer.parseInt(idStr);
    if (id <= 0) {
      response.sendRedirect(request.getContextPath() + "/usuario.jsp");
      return;
    }
  } catch (NumberFormatException e) {
    response.sendRedirect(request.getContextPath() + "/usuario.jsp");
    return;
  }

%>
  <div class="container">
    <div class="confirm-box">
      <h2>
        <i class="fa fa-user-times" aria-hidden="true"></i>
        Eliminar Usuario #<%= id %>
      </h2>
      <p>¿Estás seguro de que deseas eliminar este usuario definitivamente?</p>
      <form method="post" action="<%= request.getContextPath() %>/guardarUsuario.jsp">
        <input type="hidden" name="id" value="<%= id %>" />
        <input type="hidden" name="accion" value="eliminar" />
        <div class="actions">
          <button type="submit" class="btn-yes">
            <i class="fa fa-trash-alt" aria-hidden="true"></i> Sí, eliminar
          </button>
          <button type="button" class="btn-cancel" onclick="window.location.href='<%= request.getContextPath() %>/usuario.jsp'">
            <i class="fa fa-times" aria-hidden="true"></i> Cancelar
          </button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
