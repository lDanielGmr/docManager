<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Area" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("area.jsp"); return; }
    int id = Integer.parseInt(idParam);
    Area area = Area.findById(id);
    if (area == null) { response.sendRedirect("area.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Modificar Área</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    .form-container { width:90%; max-width:400px; margin:20px auto; padding:20px; background:#fff; border-radius:6px; box-shadow:0 4px 12px rgba(0,0,0,0.1); font-family:'Segoe UI',sans-serif; }
    h2 { font-size:1.5rem; margin-bottom:16px; color:#333; text-align:center; }
    form { display:flex; flex-direction:column; gap:12px; }
    label { font-weight:bold; }
    input[type="text"] { padding:8px; border:1px solid #ccc; border-radius:4px; font-size:1rem; }
    .buttons { display:flex; justify-content:space-between; margin-top:16px; }
    button { padding:8px 16px; border:none; border-radius:4px; font-size:0.95rem; cursor:pointer; }
    button.save { background:#007bff; color:#fff; }
    button.cancel { background:#6c757d; color:#fff; }
  </style>
  <script>
    window.resizeTo(620, 440);
    function closeAndRefresh() {
      if (window.opener && !window.opener.closed) window.opener.location.reload();
      window.close();
    }
  </script>
</head>
<body>
  <div class="form-container">
    <h2>Modificar Área</h2>
    <form action="guardarArea.jsp" method="post" onsubmit="setTimeout(closeAndRefresh,100);">
      <input type="hidden" name="id" value="<%= area.getId() %>">
      <label for="nombre">Nombre del Área</label>
      <input type="text" id="nombre" name="nombre" value="<%= area.getNombre() %>" required>
      <div class="buttons">
        <button type="button" class="cancel" onclick="window.close()"><i class="fas fa-times"></i> Cancelar</button>
        <button type="submit" class="save"><i class="fas fa-save"></i> Guardar Cambios</button>
      </div>
    </form>
  </div>
</body>
</html>
