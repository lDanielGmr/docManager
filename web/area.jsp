<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="java.util.List, clasesGenericas.Area" %>
<%@ include file="menu.jsp" %>

<%
    List<Area> areas = Area.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Áreas</title>
  <link rel="stylesheet" href="style.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
  <style>
    :root {
      --bg: #1f1f2e;
      --accent: #9d7aed;
      --text: #e0e0e0;
      --light: #fff;
      --shadow: rgba(0, 0, 0, 0.4);
    }
    html, body {
      margin: 0;
      padding: 0;
      height: 100%;
      overflow-y: auto;
    }
    * {
      box-sizing: border-box;
      font-family: 'Poppins', sans-serif;
    }

    .menu-container {
      width: 100%;
      max-width: 960px;
      margin: 20px auto;
      padding: 0 10px;
    }

    .menu-box {
      background: #fff;
      padding: 16px;
      border-radius: 4px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      line-height: 1.5;
    }

    h2 {
      font-size: 1.5rem;
      margin-bottom: 14px;
      color: #000;
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
      border: 1px solid #ccc;
    }

    .docs-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 16px;
      background-color: #fff;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
      border-radius: 6px;
      overflow: hidden;
    }

    .docs-table th,
    .docs-table td {
      padding: 12px 10px;
      text-align: left;
      font-size: 0.9rem;
      border-bottom: 1px solid #dcdcdc;
      color: #2b2b2b;
      background-color: #ffffff;
    }

    .docs-table th {
      background-color: #f0f4f8;
      font-weight: bold;
      text-transform: uppercase;
      font-size: 0.85rem;
      color: #1a1a1a;
      border-bottom: 2px solid #ccc;
    }

    .docs-table tr:hover {
      background-color: #f5faff;
      transition: background-color 0.2s ease;
    }

    .docs-table tr:last-child td {
      border-bottom: none;
    }

    .actions {
      display: flex;
      justify-content: flex-end;
      gap: 6px;
      flex-wrap: wrap;
    }

    .actions button {
      background-color: #f0f0f0;
      border: 1px solid #bbb;
      color: #333;
      padding: 6px 12px;
      border-radius: 4px;
      cursor: pointer;
      transition: background-color 0.2s ease, border-color 0.2s ease;
    }

    .actions button:hover {
      background-color: #e4e4e4;
      border-color: #999;
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

    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.5);
      display: none;
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }

    .modal-content {
      background: #fff;
      width: 90%;
      max-width: 760px;
      height: auto;
      border-radius: 6px;
      position: relative;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
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

    .modal-iframe {
      width: 100%;
      height: 580px;
      border: none;
      border-radius: 0 0 6px 6px;
    }

    tr.select {
      background: #e6f7ff !important;
    }
  </style>
</head>
<body class="theme-black-text">
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Áreas</h2>

      <div class="toolbar">
        <button id="btnAddArea"><i class="fas fa-plus"></i> Añadir Área</button>
      </div>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Número</th>
            <th>Nombre</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% int idx = 1;
             for (Area a : areas) { %>
            <tr>
              <td><%= idx++ %></td>
              <td><%= a.getNombre() %></td>
              <td class="actions">
                <button class="btnEdit" data-id="<%= a.getId() %>">
                  <i class="fas fa-edit"></i> Modificar
                </button>
                <button onclick="if(confirm('¿Eliminar área «<%= a.getNombre() %>»?')) 
                                  window.location='eliminarArea.jsp?id=<%= a.getId() %>'">
                  <i class="fas fa-trash"></i> Eliminar
                </button>
              </td>
            </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>

  <div class="modal-overlay" id="modalArea">
    <div class="modal-content">
      <button class="modal-close" id="closeModalArea">&times;</button>
      <iframe class="modal-iframe" id="iframeArea" src="about:blank"></iframe>
    </div>
  </div>

  <script>
    const ctx      = '<%= request.getContextPath() %>';
    const modal    = document.getElementById('modalArea');
    const iframe   = document.getElementById('iframeArea');
    const btnAdd   = document.getElementById('btnAddArea');
    const btnClose = document.getElementById('closeModalArea');

    function closeParentModal() {
      modal.style.display = 'none';
      iframe.src = 'about:blank';
    }

    btnAdd.addEventListener('click', () => {
      iframe.src = ctx + '/adicionarArea.jsp';
      modal.style.display = 'flex';
    });

    document.querySelectorAll('.btnEdit').forEach(btn => {
      btn.addEventListener('click', () => {
        iframe.src = ctx + '/modificarArea.jsp?id=' + btn.dataset.id;
        modal.style.display = 'flex';
      });
    });

    function cerrarModalYRecargar() {
      closeParentModal();
      window.location.reload();
    }

    btnClose.addEventListener('click', cerrarModalYRecargar);
    window.addEventListener('click', e => {
      if (e.target === modal) cerrarModalYRecargar();
    });
  </script>
</body>
</html>
