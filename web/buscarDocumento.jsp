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

    String nombre       = request.getParameter("nombre");
    String fechaDesde   = request.getParameter("fechaDesde");
    String fechaHasta   = request.getParameter("fechaHasta");
    String tipo         = request.getParameter("tipo");
    String etiqueta     = request.getParameter("etiqueta");
    boolean soloPlantillas = "on".equals(request.getParameter("soloPlantillas"));

    StringBuilder sql = new StringBuilder(
      "SELECT d.id, d.titulo, d.tipo, DATE(d.fecha_creacion) AS fecha " +
      "FROM documento d " +
      "LEFT JOIN docu_etiqueta de ON d.id = de.doc_id " +
      "LEFT JOIN etiqueta e ON de.etq_id = e.id " +
      "WHERE d.eliminado = 0"
    );
    List<Object> params = new ArrayList<>();
    if (nombre != null && !nombre.trim().isEmpty()) {
        sql.append(" AND d.titulo LIKE ?"); params.add("%"+nombre.trim()+"%");
    }
    if (fechaDesde != null && !fechaDesde.isEmpty()) {
        sql.append(" AND d.fecha_creacion>=?"); params.add(fechaDesde+" 00:00:00");
    }
    if (fechaHasta != null && !fechaHasta.isEmpty()) {
        sql.append(" AND d.fecha_creacion<=?"); params.add(fechaHasta+" 23:59:59");
    }
    if (tipo != null && !tipo.isEmpty()) {
        sql.append(" AND d.tipo=?"); params.add(tipo);
    }
    if (etiqueta != null && !etiqueta.trim().isEmpty()) {
        sql.append(" AND e.nombre=?"); params.add(etiqueta.trim());
    }
    if (soloPlantillas) {
        sql.append(" AND d.es_plantilla=TRUE");
    }
    sql.append(" GROUP BY d.id ORDER BY d.fecha_creacion DESC");

    List<Map<String,Object>> resultados = new ArrayList<>();
    try {
        String DB_URL  = "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=UTC";
        String DB_USER = "tu_usuario";
        String DB_PASS = "tu_contraseña";
        try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement pst = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                pst.setObject(i+1, params.get(i));
            }
            try (ResultSet rs = pst.executeQuery()) {
                while (rs.next()) {
                    Map<String,Object> row = new HashMap<>();
                    row.put("id",     rs.getInt("id"));
                    row.put("titulo", rs.getString("titulo"));
                    row.put("tipo",   rs.getString("tipo"));
                    row.put("fecha",  rs.getDate("fecha"));
                    resultados.add(row);
                }
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
  <title>Búsqueda Avanzada</title>
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
      <h2>Búsqueda Avanzada</h2>

      <section class="toolbar">
        <input type="text" name="nombre" placeholder="Título" value="<%= nombre!=null?nombre:"" %>">
        <input type="date" name="fechaDesde" value="<%= fechaDesde!=null?fechaDesde:"" %>">
        <input type="date" name="fechaHasta" value="<%= fechaHasta!=null?fechaHasta:"" %>">
        <select name="tipo">
          <option value="">-- Tipo --</option>
          <option value="Informe"  <%= "Informe".equals(tipo)?"selected":"" %>>Informe</option>
          <option value="Memo"     <%= "Memo".equals(tipo)?"selected":"" %>>Memo</option>
          <option value="Contrato" <%= "Contrato".equals(tipo)?"selected":"" %>>Contrato</option>
        </select>
        <input type="text" name="etiqueta" placeholder="Etiqueta" value="<%= etiqueta!=null?etiqueta:"" %>">
        <label style="display:flex;align-items:center;gap:4px;">
          <input type="checkbox" name="soloPlantillas" <%= soloPlantillas?"checked":"" %> > Sólo plantillas
        </label>
        <button onclick="applyFilters()">Aplicar filtros</button>
      </section>

      <table class="docs-table" id="tablaDocs">
        <thead>
          <tr>
            <th>Numero</th><th>Documento</th><th>Tipo</th><th>Fecha</th><th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <% if (resultados.isEmpty()) { %>
            <tr><td colspan="5" style="text-align:center;">No se encontraron documentos</td></tr>
          <% } else {
               int i=1;
               for (Map<String,Object> d : resultados) { %>
            <tr>
              <td><%= i++ %></td>
              <td><%= d.get("titulo") %></td>
              <td><%= d.get("tipo")   %></td>
              <td><%= d.get("fecha")  %></td>
              <td>
                <button onclick="ver(<%= d.get("id") %>)">Ver</button>
                <button onclick="descargar(<%= d.get("id") %>)">Descargar</button>
                <button onclick="editar(<%= d.get("id") %>)">Editar</button>
              </td>
            </tr>
          <%   }
             }
          %>
        </tbody>
      </table>
    </div>
  </div>

  <script>
    function applyFilters(){
      const qs = [];
      const fp = document.querySelector('.toolbar');
      fp.querySelectorAll('input[name], select[name]').forEach(el=>{
        if ((el.type==='checkbox' && el.checked) ||
            (el.type!=='checkbox' && el.value.trim()!=='')) {
          qs.push(encodeURIComponent(el.name)+'='+encodeURIComponent(el.value));
        }
      });
      window.location.href = 'buscarDocumento.jsp?' + qs.join('&');
    }
    function ver(id){ window.open('verDocumento?id='+id,'_blank'); }
    function descargar(id){ location.href='descargarDocumento?id='+id; }
    function editar(id){ location.href='editarDocumento.jsp?id='+id; }
  </script>
</body>
</html>
