<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>

<%
    String temaActual     = (String) session.getAttribute("tema");
    String lenguajeActual = (String) session.getAttribute("lenguaje");
    if (temaActual == null)     temaActual     = "claro";
    if (lenguajeActual == null) lenguajeActual = "español";
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Preferencias</title>
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
    color: #333;
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
  }

  .docs-table th,
  .docs-table td {
    padding: 10px 6px; 
    border: 1px solid #ddd;
    font-size: 0.85rem;
    word-break: break-word;
  }

  .docs-table th {
    background: #f5f5f5;
    text-transform: uppercase;
  }

  .docs-table tr:hover {
    background: #fafafa;
    cursor: pointer;
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

  tr.select    background: #e6f7ff !important;
  }
  html, body {
  margin: 0;
  padding: 0;
  height: 100%;
  overflow-y: auto;
  background: var(--bg);
  color: var(--text); 
}

* {
  box-sizing: border-box;
  font-family: 'Poppins', sans-serif;
  color: inherit;
}

.menu-box {
  background: #fff;
  color: #000; 
}

.shortcut-tags {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  margin-bottom: 20px;
}

.shortcut-tags .card {
  flex: 1 1 45%; 
  background: #fdfdfd;
  border: 1px solid #ddd;
  border-radius: 6px;
  padding: 16px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.05);
}

.shortcut-tags .card h2 {
  font-size: 1.2rem;
  margin-bottom: 10px;
  color: #444;
}

.shortcut-tags ul {
  list-style: none;
  padding-left: 0;
  margin: 0;
}

.shortcut-tags li {
  margin-bottom: 8px;
  font-size: 0.95rem;
  color: #222;
  display: flex;
  align-items: center;
}

.shortcut-tags li i {
  margin-right: 6px;
  color: var(--accent);
}

</style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Preferencias</h2>

      <form action="GuardarPreferenciasServlet" method="post" class="prefs-form">
        <div class="prefs-row">
          <label>TEMA:</label>
          <div class="btn-group">
            <button type="submit" name="tema" value="claro"
              style="<%= "claro".equals(temaActual) ? "background:#ddd;" : "" %>">
              CLARO
            </button>
            <button type="submit" name="tema" value="oscuro"
              style="<%= "oscuro".equals(temaActual) ? "background:#ddd;" : "" %>">
              OSCURO
            </button>
          </div>
        </div>

        <div class="prefs-row">
          <label>IDIOMA:</label>
          <select name="lenguaje">
            <option value="español" <%= "español".equals(lenguajeActual) ? "selected" : "" %>>
              ESPAÑOL
            </option>
            <option value="inglés" <%= "inglés".equals(lenguajeActual) ? "selected" : "" %>>
              INGLÉS
            </option>
            <option value="portugués" <%= "portugués".equals(lenguajeActual) ? "selected" : "" %>>
              PORTUGUÉS
            </option>
          </select>
        </div>

        <div class="form-actions">
          <button type="submit">GUARDAR PREFERENCIAS</button>
          <button type="button" onclick="window.location='inicio.jsp'">CANCELAR</button>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
