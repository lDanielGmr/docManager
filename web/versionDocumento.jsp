<%@ page import="
    java.sql.*,
    java.util.*,
    clasesGenericas.Documento,
    clasesGenericas.Usuario
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>

<%

    boolean puedeBuscar = false;
    Integer pidBuscar = mapaPermisos.get("ver_busquedas");
    if (pidBuscar != null && permisosRol.contains(pidBuscar)) {
        puedeBuscar = true;
    }

    boolean puedeRestaurar = false;
    Integer pidRestaurar = mapaPermisos.get("restaurar_documento");
    if (pidRestaurar != null && permisosRol.contains(pidRestaurar)) {
        puedeRestaurar = true;
    }


    String nombre   = request.getParameter("nombre");
    String docIdStr = request.getParameter("docId");
    Integer docId   = null;
    if (docIdStr != null) {
        try { docId = Integer.valueOf(docIdStr); }
        catch (NumberFormatException ignored) {}
    }

    List<Map<String,Object>> docs = new ArrayList<>();
    String sqlDocs = "SELECT id, titulo FROM documento WHERE eliminado=0"
                   + (nombre!=null && !nombre.trim().isEmpty() ? " AND titulo LIKE ?" : "")
                   + " ORDER BY fecha_creacion DESC";
    try (Connection con = DriverManager.getConnection(
             "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=UTC",
             "root","admin");
         PreparedStatement pst = con.prepareStatement(sqlDocs)) {

        if (nombre!=null && !nombre.trim().isEmpty()) {
            pst.setString(1, "%" + nombre.trim() + "%");
        }
        try (ResultSet rs = pst.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> d = new HashMap<>();
                d.put("id", rs.getInt("id"));
                d.put("titulo", rs.getString("titulo"));
                docs.add(d);
            }
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }

    List<Map<String,Object>> versiones = new ArrayList<>();
    if (docId != null) {
        String sqlVer = "SELECT v.id, v.numero, DATE(v.timestamp) AS fecha, u.nombre AS autor "
                      + "FROM version v "
                      + "JOIN documento d ON v.doc_id=d.id "
                      + "JOIN usuario u ON v.doc_id=u.id "
                      + "WHERE v.doc_id=? ORDER BY v.numero ASC";
        try (Connection con = DriverManager.getConnection(
                 "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=UTC",
                 "root","admin");
             PreparedStatement pst = con.prepareStatement(sqlVer)) {

            pst.setInt(1, docId);
            try (ResultSet rs = pst.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> v = new HashMap<>();
                    v.put("id",     rs.getInt("id"));
                    v.put("numero", "V" + rs.getInt("numero"));
                    v.put("fecha",  rs.getDate("fecha"));
                    v.put("autor",  rs.getString("autor"));
                    versiones.add(v);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Versiones de Documento</title>
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
      <h2>Versiones de Documento</h2>

      <% if (puedeBuscar) { %>
        <section class="toolbar">
          <input type="text" id="nombre" placeholder="Buscar documento"
                 value="<%= nombre!=null?nombre:"" %>">
          <button onclick="buscar()">Buscar</button>
          <button onclick="limpiar()">Limpiar</button>
        </section>
      <% } %>

      <div class="section-box">
        <h3>Documentos encontrados</h3>
        <table class="docs-table">
          <thead>
            <tr><th>Numero</th><th>Documento</th><th>Seleccionar</th></tr>
          </thead>
          <tbody>
            <% if (docs.isEmpty()) { %>
              <tr><td colspan="3" style="text-align:center;">No hay documentos</td></tr>
            <% } else {
                 int i=1;
                 for (Map<String,Object> d : docs) { %>
              <tr>
                <td><%= i++ %></td>
                <td><%= d.get("titulo") %></td>
                <td>
                  <button onclick="mostrarVersiones(<%= d.get("id") %>)">Versiones</button>
                </td>
              </tr>
            <% }} %>
          </tbody>
        </table>
      </div>

      <div class="section-box">
        <h3>Versiones del documento</h3>
        <table class="docs-table">
          <thead>
            <tr><th>Numero</th><th>Versión</th><th>Fecha</th><th>Autor</th><th>Acciones</th></tr>
          </thead>
          <tbody>
            <% if (docId == null) { %>
              <tr><td colspan="5" style="text-align:center;">Selecciona un documento</td></tr>
            <% } else if (versiones.isEmpty()) { %>
              <tr><td colspan="5" style="text-align:center;">Sin versiones</td></tr>
            <% } else {
                 int j=1;
                 for (Map<String,Object> v : versiones) { %>
              <tr>
                <td><%= j++ %></td>
                <td><%= v.get("numero") %></td>
                <td><%= v.get("fecha")  %></td>
                <td><%= v.get("autor")  %></td>
                <td class="actions">
                  <% if (puedeRestaurar) { %>
                    <button onclick="restaurar(<%= v.get("id") %>)">Restaurar</button>
                  <% } %>
                  <button onclick="descargarVer(<%= v.get("id") %>)">Descargar</button>
                </td>
              </tr>
            <% }} %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <script>
    function buscar(){
      const n = encodeURIComponent(document.getElementById('nombre').value);
      window.location = 'versionDocumento.jsp?nombre=' + n;
    }
    function limpiar(){
      window.location = 'versionDocumento.jsp';
    }
    function mostrarVersiones(id){
      const n = encodeURIComponent(document.getElementById('nombre').value);
      window.location = 'versionDocumento.jsp?nombre=' + n + '&docId=' + id;
    }
    function restaurar(vid){
      window.location = 'restaurarVersion?vid=' + vid;
    }
    function descargarVer(vid){
      window.location = 'descargarVersion?vid=' + vid;
    }
  </script>
</body>
</html>
