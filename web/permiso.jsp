<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, java.util.Set, java.util.HashSet, clasesGenericas.Rol, clasesGenericas.Permiso, clasesGenericas.RolPermiso" %>
<%@ include file="menu.jsp" %>

<%
    List<Rol> roles = Rol.findAll();
    List<Permiso> listaPermisos = Permiso.findAll();

    String rolParam = request.getParameter("rolId");
    int rolIdSel = -1;
    if (rolParam != null && !rolParam.isEmpty()) {
        try {
            rolIdSel = Integer.parseInt(rolParam);
        } catch (NumberFormatException e) {
            rolIdSel = -1;
        }
    }

    Set<Integer> asignados = new HashSet<>();
    if (rolIdSel > 0) {
        for (RolPermiso rp : RolPermiso.findByRolId(rolIdSel)) {
            asignados.add(rp.getPermisoId());
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Permisos</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #007bff;
      --accent-hover: #0056b3;
      --text: #e0e0e0;
      --light: #fff;
      --shadow: rgba(0, 0, 0, 0.4);
      --gap: 12px;
    }
    html, body {
      margin: 0; padding: 0; height: 100%;
      background: var(--bg) url('${pageContext.request.contextPath}/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
      color: var(--text);
      font-family: 'Poppins', sans-serif;
    }
    *, *::before, *::after { box-sizing: border-box; }
    .menu-container {
      max-width: 960px; margin: 20px auto; padding: 0 10px;
    }
    .menu-box {
      background: #fff; color: #000;
      padding: 16px; border-radius: 4px;
      box-shadow: 0 4px 12px var(--shadow);
    }
    h2 {
      font-size: 1.5rem; margin-bottom: 14px; color: #333;
    }

    .toolbar {
      display: flex; align-items: center; gap: 10px; margin-bottom: 20px;
    }
    .toolbar label { font-weight: bold; color: #333; }
    .toolbar select {
      padding: 6px 10px; font-size: 0.95rem;
      border: 1px solid #ccc; border-radius: 4px;
      color: #000; cursor: pointer;
      transition: border-color .2s;
    }
    .toolbar select:focus { border-color: var(--accent); outline: none; }

    .perms-grid {
      display: flex; flex-wrap: wrap; gap: var(--gap); margin-top: 20px;
    }
    .perm-item {
      flex: 0 0 calc((100% - 6 * var(--gap)) / 7);
      display: flex; align-items: center;
      background: #f8f8f8; padding: 8px 10px;
      border: 1px solid #ddd; border-radius: 4px;
      cursor: pointer; transition: background .2s;
    }
    .perm-item:hover { background: #e6f0ff; }
    .perm-item input[type="checkbox"] {
      margin-right: 8px; accent-color: var(--accent);
      width: 18px; height: 18px; cursor: pointer;
    }

    .actions {
      display: flex; justify-content: flex-end; margin-top: 20px;
    }
    .actions button {
      display: flex; align-items: center; gap: 6px;
      padding: 8px 16px; font-size: .95rem;
      background: var(--accent); color: var(--light);
      border: none; border-radius: 4px;
      cursor: pointer; transition: background .2s;
    }
    .actions button:hover { background: var(--accent-hover); }
    .actions button i { font-size: 1.1rem; }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Asignar Permisos a Roles</h2>

      <form method="get" class="toolbar">
        <label for="rolSelect">
          <i class="fas fa-user-tag" style="color:var(--accent)"></i> Rol:
        </label>
        <select name="rolId" id="rolSelect" onchange="this.form.submit()">
          <option value="">-- Seleccione un rol --</option>
          <% for (Rol r : roles) { %>
            <option value="<%=r.getId()%>" <%= r.getId()==rolIdSel?"selected":"" %>><%= r.getNombre() %></option>
          <% } %>
        </select>
      </form>

      <% if (rolIdSel > 0) { %>
        <form action="guardarRolPermiso.jsp" method="post">
          <input type="hidden" name="rolId" value="<%=rolIdSel%>"/>
          <div class="perms-grid">
            <% for (Permiso p : listaPermisos) { %>
              <label class="perm-item">
                <input type="checkbox" name="permisoId" value="<%=p.getId()%>" <%= asignados.contains(p.getId()) ? "checked" : "" %>/>
                <span><%=p.getNombre()%></span>
              </label>
            <% } %>
          </div>
          <div class="actions">
            <button type="submit"><i class="fas fa-save"></i> Guardar</button>
          </div>
        </form>
      <% } else { %>
        <p>Selecciona un rol para ver y asignar permisos.</p>
      <% } %>

    </div>
  </div>
</body>
</html>
