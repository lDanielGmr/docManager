<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, clasesGenericas.Etiqueta" %>
<%@ include file="menu.jsp" %>

<%
    List<Etiqueta> etiquetas = Etiqueta.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Etiquetas</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <style>
  :root {
    --text: #e0e0e0;
    --white: #ffffff;
    --black: #000000;
    --border: #ccc;
    --hover-bg: #2a2a3d;
  }

  html, body {
    margin: 0;
    padding: 0;
    height: 100%;
    background: url("images/login-bg.jpg") no-repeat center center fixed;
    background-size: cover;
    color: var(--text);
    font-family: 'Poppins', sans-serif;
  }

  * {
    box-sizing: border-box;
    color: inherit;
  }

  .menu-container {
    max-width: 960px;
    margin: 40px auto;
    padding: 0 16px;
  }

  .menu-box {
    background: var(--white);
    color: var(--black);
    padding: 24px;
    border-radius: 8px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.5);
  }

  .menu-box * {
    color: var(--black);
  }

  h2 {
    margin-bottom: 20px;
    font-size: 1.8rem;
    color: var(--black);
  }

  .toolbar {
    display: flex;
    justify-content: flex-start;
    margin-bottom: 16px;
    gap: 10px;
  }

  .toolbar button {
    background: var(--white);
    color: var(--black);
    border: 1.5px solid var(--black);
    padding: 10px 16px;
    border-radius: 6px;
    font-size: 0.95rem;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .toolbar button:hover {
    background: var(--black);
    color: var(--white);
  }

  table.etq-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
  }

  .etq-table th, .etq-table td {
    padding: 12px;
    border: 1px solid var(--border);
    text-align: left;
    font-size: 0.95rem;
    background: rgba(0, 0, 0, 0.03);
    color: var(--black);
  }

  .etq-table th {
    background-color: rgba(0, 0, 0, 0.05);
    text-transform: uppercase;
  }

  .etq-table tr:hover {
    background-color: rgba(0, 0, 0, 0.08);
    cursor: pointer;
  }

  .etq-table tr.selected {
    background-color: rgba(0, 0, 0, 0.15) !important;
  }

  .actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    flex-wrap: wrap;
  }

  .actions button {
    background: var(--white);
    color: var(--black);
    border: 1.5px solid var(--black);
    padding: 8px 14px;
    font-size: 0.9rem;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .actions button:hover {
    background: var(--black);
    color: var(--white);
  }

  .modal-overlay {
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal-content {
    background: var(--white);
    color: var(--black);
    padding: 24px;
    border-radius: 8px;
    max-width: 480px;
    width: 90%;
    position: relative;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
  }

  .modal-close {
    position: absolute;
    top: 10px; right: 10px;
    background: transparent;
    border: none;
    font-size: 1.5rem;
    cursor: pointer;
    color: var(--black);
  }

  #formEtq label {
    display: block;
    margin-bottom: 6px;
    font-weight: 500;
    color: var(--black);
  }

  #formEtq input[type="text"] {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--border);
    border-radius: 6px;
    margin-bottom: 20px;
    font-size: 1rem;
    color: var(--black);
  }

  #formEtq button[type="submit"] {
    background: var(--white);
    color: var(--black);
    border: 1.5px solid var(--black);
    padding: 10px 20px;
    font-size: 1rem;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  #formEtq button[type="submit"]:hover {
    background: var(--black);
    color: var(--white);
  }
</style>

</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Etiquetas</h2>

      <section class="toolbar">
        <button id="btnOpenAdd"><i class="fas fa-plus"></i> Añadir etiqueta</button>
      </section>

      <section>
        <table class="etq-table" id="tablaEtq">
          <thead>
            <tr>
              <th>Numero</th><th>Nombre</th>
            </tr>
          </thead>
          <tbody>
            <% int idx = 1;
               for (Etiqueta e : etiquetas) { %>
            <tr data-id="<%= e.getId() %>" onclick="seleccionar(this)">
              <td><%= idx++ %></td>
              <td><%= e.getNombre() %></td>
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
      <form id="formEtq" method="post">
        <input type="hidden" name="id" id="etqId">
        <label for="etqNombre">Nombre etiqueta</label>
        <input type="text" name="nombre" id="etqNombre" required>
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
          form = document.getElementById('formEtq'),
          nombreInput = document.getElementById('etqNombre'),
          idInput = document.getElementById('etqId'),
          submitBtn = document.getElementById('submitBtn');

    document.getElementById('btnOpenAdd').onclick = () => {
      idInput.value = '';
      nombreInput.value = '';
      submitBtn.textContent = 'Añadir';
      form.action = 'adicionarEtiqueta.jsp';
      modal.style.display = 'flex';
    };

    document.getElementById('btnEdit').onclick = () => {
      if (!selectedRow) return alert('Selecciona una etiqueta');
      idInput.value = selectedRow.dataset.id;
      nombreInput.value = selectedRow.cells[1].textContent.trim();
      submitBtn.textContent = 'Modificar';
      form.action = 'modificarEtiqueta.jsp';
      modal.style.display = 'flex';
    };

    document.getElementById('btnDelete').onclick = () => {
      if (!selectedRow) return alert('Selecciona una etiqueta');
      if (confirm('Eliminar etiqueta "' + selectedRow.cells[1].textContent + '"?')) {
        window.location = 'eliminarEtiqueta.jsp?id=' + selectedRow.dataset.id;
      }
    };

    document.getElementById('btnClose').onclick = () => modal.style.display = 'none';
    window.onclick = e => { if (e.target === modal) modal.style.display = 'none'; };
  </script>
</body>
</html>
