<%@ page import="
    java.sql.*,
    java.util.*,
    clasesGenericas.Usuario
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>

<%

    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    boolean puedeBuscar = false;
    Integer pidBuscar = mapaPermisos.get("ver_busquedas");
    if (pidBuscar != null && permisosRol.contains(pidBuscar)) {
        puedeBuscar = true;
    }

    String nombreFiltro = request.getParameter("nombre");

    List<Map<String,Object>> papeles = new ArrayList<>();
    String sql = 
      "SELECT p.id, d.titulo, DATE(p.fecha_elim) AS fechaElim, u.nombre AS autor " +
      "FROM papelera p " +
      "JOIN documento d ON p.doc_id = d.id " +
      "JOIN usuario u ON d.recibido_por = u.id " +
      "WHERE d.eliminado = 1" +
      (nombreFiltro != null && !nombreFiltro.trim().isEmpty()
        ? " AND d.titulo LIKE ?" : "") +
      " ORDER BY p.fecha_elim DESC";

    try (Connection con = DriverManager.getConnection(
             "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=UTC",
             "tu_usuario","tu_contraseña");
         PreparedStatement pst = con.prepareStatement(sql)) {

        if (nombreFiltro != null && !nombreFiltro.trim().isEmpty()) {
            pst.setString(1, "%" + nombreFiltro.trim() + "%");
        }
        try (ResultSet rs = pst.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("id",        rs.getInt("id"));
                row.put("titulo",    rs.getString("titulo"));
                row.put("fechaElim", rs.getDate("fechaElim"));
                row.put("autor",     rs.getString("autor"));
                papeles.add(row);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Papelera</title>
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
      <h2>Papelera</h2>

      <% if (puedeBuscar) { %>
        <section class="toolbar">
          <input 
            type="text" id="nombre" placeholder="Buscar documento eliminado"
            value="<%= nombreFiltro!=null?nombreFiltro:"" %>"
          >
          <button onclick="buscar()">Buscar</button>
          <button onclick="limpiar()">Limpiar</button>
        </section>
      <% } %>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Numero</th>
            <th>Nombre Documento</th>
            <th>Fecha Eliminación</th>
            <th>Autor</th>
            <th>Restaurar</th>
          </tr>
        </thead>
        <tbody>
          <% if (papeles.isEmpty()) { %>
            <tr>
              <td colspan="5" style="text-align:center;">No hay documentos en la papelera</td>
            </tr>
          <% } else {
               for (Map<String,Object> p : papeles) { %>
            <tr>
              <td><%= p.get("id") %></td>
              <td><%= p.get("titulo") %></td>
              <td><%= p.get("fechaElim") %></td>
              <td><%= p.get("autor") %></td>
              <td class="actions">
                <button onclick="restaurar(<%= p.get("id") %>)">Restaurar</button>
              </td>
            </tr>
          <% } } %>
        </tbody>
      </table>
    </div>
  </div>

  <script>
    function buscar() {
      const n = encodeURIComponent(document.getElementById('nombre').value);
      window.location = 'papelera.jsp?nombre=' + n;
    }
    function limpiar() {
      window.location = 'papelera.jsp';
    }
    function restaurar(id) {
      window.location = 'restaurarDocumento?id=' + id;
    }
  </script>
</body>
</html>
