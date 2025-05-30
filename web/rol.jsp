<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, clasesGenericas.Rol" %>
<%@ include file="menu.jsp" %>

<%
    List<Rol> roles = Rol.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Roles</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <style>
:root {
  --bg: #1f1f2e;
  --accent: #007BFF;
  --text: #e0e0e0;
  --light: #fff;
  --shadow: rgba(0, 0, 0, 0.4);

  --border-light: #ddd;
  --border-dark: #ccc;
  --hover-light: #fafafa;
  --table-header-bg: #f5f5f5;
  --text-dark: #222;
  --text-header: #444;
}

* {
  box-sizing: border-box;
  font-family: 'Poppins', sans-serif;
  color: inherit;
}

html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  overflow-y: auto;
  background-color: var(--bg);
  background-image: url("images/login-bg.jpg"); 
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  color: var(--text);
}

.menu-container {
  width: 100%;
  max-width: 960px;
  margin: 20px auto;
  padding: 0 10px;
}

.menu-box {
  background: var(--light);
  padding: 16px;
  border-radius: 4px;
  box-shadow: 0 4px 12px var(--shadow);
  color: #000;
}

h2 {
  font-size: 1.5rem;
  margin-bottom: 14px;
  color: var(--text-header);
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 14px;
}

.toolbar button,
.toolbar input {
  font-size: 0.9rem;
  padding: 6px 10px;
  border-radius: 4px;
}

.toolbar input {
  flex: 1;
  border: 1px solid var(--border-dark);
  background: #fff;
  color: #000;
}

.roles-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 16px;
}

.roles-table th,
.roles-table td {
  padding: 10px 6px;
  border: 1px solid var(--border-light);
  font-size: 0.85rem;
  word-break: break-word;
  color: var(--text-dark);
}

.roles-table th {
  background: var(--table-header-bg);
  text-transform: uppercase;
  color: var(--text-header);
}

.roles-table tr:hover {
  background: var(--hover-light);
  cursor: pointer;
}

.roles-table tr.selected {
  background: #e6f7ff !important;
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: 6px;
  flex-wrap: wrap;
}

.actions button {
  font-size: 0.85rem;
  padding: 6px 12px;
  border-radius: 4px;
  border: 1.5px solid #000;
  background-color: #fff;
  color: #000;
  cursor: pointer;
  transition: background 0.2s ease, color 0.2s ease;
}

.actions button:hover {
  background-color: #000;
  color: #fff;
  border-color: #000;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0,0,0,0.5);
  display: none;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--light);
  width: 90%;
  max-width: 760px;
  height: auto;
  border-radius: 6px;
  position: relative;
  box-shadow: 0 4px 12px var(--shadow);
  padding: 20px;
  color: #000;
}

.modal-close {
  position: absolute;
  top: 10px;
  right: 10px;
  background: transparent;
  border: none;
  font-size: 1.4rem;
  cursor: pointer;
}

#formRol label {
  display: block;
  margin-bottom: 6px;
  font-weight: 600;
}

#formRol input[type="text"] {
  width: 100%;
  padding: 8px 10px;
  margin-bottom: 16px;
  border: 1px solid var(--border-dark);
  border-radius: 4px;
  font-size: 1rem;
  color: #000;
}

#formRol button[type="submit"] {
  background-color: var(--accent);
  border: none;
  color: var(--light);
  padding: 10px 20px;
  font-size: 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background 0.2s ease;
}

#formRol button[type="submit"]:hover {
  background-color: #7e5bef;
}
</style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Roles</h2>

      <section class="toolbar">
        <button id="btnAdd"><i class="fas fa-plus"></i> Añadir rol</button>
      </section>

      <section>
        <table class="roles-table" id="tablaRoles">
          <thead>
            <tr><th>Numero</th><th>Nombre</th></tr>
          </thead>
          <tbody>
            <% int idx = 1;
               for (Rol r : roles) { %>
            <tr data-id="<%= r.getId() %>" onclick="seleccionar(this)">
              <td><%= idx++ %></td>
              <td><%= r.getNombre() %></td>
            </tr>
            <% } %>
          </tbody>
        </table>
      </section>

      <section class="actions">
        <button id="btnEdit"><i class="fas fa-edit"></i> Modificar</button>
        <button id="btnDelete"><i class="fas fa-trash"></i> Eliminar</button>
      </section>
    </div>
  </div>

  <div class="modal-overlay" id="modal">
    <div class="modal-content">
      <button class="modal-close" id="btnClose">&times;</button>
      <form id="formRol" method="post">
        <input type="hidden" name="id" id="rolId">
        <label for="rolNombre">Nombre del rol</label>
        <input type="text" name="nombre" id="rolNombre" required>
        <button type="submit" id="submitBtn">Guardar</button>
      </form>
    </div>
  </div>

  <script>
    let selectedRow = null;
    function seleccionar(row) {
      document.querySelectorAll('tr.selected').forEach(r => r.classList.remove('selected'));
      row.classList.add('selected');
      selectedRow = row;
    }

    const modal = document.getElementById('modal'),
          form = document.getElementById('formRol'),
          nombreInput = document.getElementById('rolNombre'),
          idInput = document.getElementById('rolId'),
          submitBtn = document.getElementById('submitBtn');

    document.getElementById('btnAdd').onclick = () => {
      idInput.value = '';
      nombreInput.value = '';
      submitBtn.textContent = 'Añadir';
      form.action = 'adicionarRol.jsp';
      modal.style.display = 'flex';
    };

    document.getElementById('btnEdit').onclick = () => {
      if (!selectedRow) return alert('Selecciona un rol');
      idInput.value = selectedRow.dataset.id;
      nombreInput.value = selectedRow.cells[1].textContent.trim();
      submitBtn.textContent = 'Modificar';
      form.action = 'modificarRol.jsp';
      modal.style.display = 'flex';
    };

    document.getElementById('btnDelete').onclick = () => {
      if (!selectedRow) return alert('Selecciona un rol');
      if (confirm('¿Eliminar rol "' + selectedRow.cells[1].textContent + '"?')) {
        window.location = 'eliminarRol.jsp?id=' + selectedRow.dataset.id;
      }
    };

    document.getElementById('btnClose').onclick = () => modal.style.display = 'none';
    window.onclick = e => { if (e.target === modal) modal.style.display = 'none'; };
  </script>
</body>
</html>
