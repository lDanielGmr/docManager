<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.util.HashSet,
    java.util.HashMap,
    java.util.Set
" %>
<%@ page import="
    clasesGenericas.Usuario,
    clasesGenericas.Menu,
    clasesGenericas.RolPermiso,
    clasesGenericas.Permiso,
    ConexionBD.conexionBD
" %>
<%@ include file="menu.jsp" %>

<%
  Object ua = session.getAttribute("user");
  Usuario usuario = ua instanceof Usuario
                    ? (Usuario) ua
                    : ua instanceof String
                      ? Usuario.findByUsuario((String) ua)
                      : null;
  if (usuario == null) {
      response.sendRedirect("index.jsp");
      return;
  }

  int roleId = usuario.getRol().getId();
  for (RolPermiso rp : RolPermiso.findByRolId(roleId)) {
      permisosRol.add(rp.getPermisoId());
  }
  for (Permiso p : Permiso.findAll()) {
      mapaPermisos.put(p.getNombre(), p.getId());
  }

  boolean puedeVerPlantillas   = permisosRol.contains(mapaPermisos.get("ver_plantillas"));
  boolean puedeVerBusquedas    = permisosRol.contains(mapaPermisos.get("ver_busquedas"));
  boolean puedeSubirDocumento  = permisosRol.contains(mapaPermisos.get("crear_documento"));
  boolean puedeEditarDocumento = permisosRol.contains(mapaPermisos.get("subir_version"));

  Menu.recordUse(request.getServletPath());

  final int PAGE_SIZE = 8;
  String sp = request.getParameter("page");
  int currentPage = 1;
  if (sp != null) {
    try { currentPage = Integer.parseInt(sp); }
    catch (NumberFormatException ignore) { }
  }
  if (currentPage < 1) currentPage = 1;

  int totalRows = 0;
  try (Connection conn = conexionBD.conectar();
       PreparedStatement cst = conn.prepareStatement(
         "SELECT COUNT(*) FROM documento d " +
         (puedeVerPlantillas ? "" : "WHERE d.es_plantilla = FALSE")
       );
       ResultSet rs = cst.executeQuery()
  ) {
    if (rs.next()) totalRows = rs.getInt(1);
  } catch (Exception e) {
    totalRows = 0;
  }

  int totalPages = (int)Math.ceil((double)totalRows / PAGE_SIZE);
  if (totalPages < 1) totalPages = 1;
  if (currentPage > totalPages) currentPage = totalPages;

  int windowSize = 5;
  int startPage  = Math.max(1, currentPage - windowSize/2);
  int endPage    = Math.min(totalPages, startPage + windowSize - 1);
  if (endPage - startPage < windowSize - 1) {
    startPage = Math.max(1, endPage - windowSize + 1);
  }
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Documentos</title>
  <link rel="stylesheet" href="style.css">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/fontawesome.css">
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
  background: var(--bg);  
  color: var(--text);
  background: url('<%=request.getContextPath()%>/images/login-bg.jpg') 
              no-repeat center center fixed;
  background-size: cover;   
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

tr.selected {
  background: #e6f7ff !important;
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

* {
  color: inherit;
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
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  margin-top: 20px;
  flex-wrap: wrap;
  list-style: none;       
  padding: 0;              
}

.pagination li {
  margin: 0;
}

.pagination li a {
  display: inline-block;
  background-color: var(--accent);
  color: #fff;
  text-decoration: none;
  padding: 10px 16px;
  font-size: 1rem;
  border-radius: 4px;
  transition: background 0.3s ease;
  min-width: 44px;
  text-align: center;
}

.pagination li a:hover:not(.disabled) {
  background-color: #7f5af0;
}

.pagination li.disabled a {
  background-color: #ccc;
  color: #666;
  pointer-events: none;
  cursor: default;
}

.pagination li.active a {
  background-color: #4e32a8;
  font-weight: bold;
  border: 2px solid #fff;
}

  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Gestión de Documentos</h2>

      <section class="toolbar">
        <% if (puedeSubirDocumento) { %>
          <button id="btnOpenModal"><i class="fas fa-upload"></i> Subir documento</button>
        <% } %>
        <% if (puedeVerBusquedas) { %>
          <input type="text" id="filtro" placeholder="Buscar documentos…">
          <button onclick="filtrar()">Buscar</button>
          <button onclick="limpiar()">Limpiar</button>
        <% } %>
      </section>

      <table class="docs-table" id="tablaDocs">
        <thead>
          <tr>
            <th>#</th><th>Nombre</th><th>Tipo</th>
            <th>Área</th><th>Subido por</th><th>Fecha</th><th>Respuesta</th>
          </tr>
        </thead>
        <tbody>
          <%
            int idx = (currentPage-1)*PAGE_SIZE + 1;
            try (Connection conn = conexionBD.conectar();
                 PreparedStatement ps = conn.prepareStatement(
                   "SELECT d.id,d.titulo,d.tipo,a.nombre AS area," +
                   "u.nombre AS usuario_nombre,d.fecha_creacion," +
                   "d.requiere_respuesta " +
                   "FROM documento d " +
                   "LEFT JOIN area a ON d.id_area=a.id " +
                   "LEFT JOIN usuario u ON d.recibido_por=u.id " +
                   (puedeVerPlantillas ? "" : "WHERE d.es_plantilla=FALSE ") +
                   "ORDER BY d.fecha_creacion DESC LIMIT ?,?"
                 )
            ) {
              ps.setInt(1, (currentPage-1)*PAGE_SIZE);
              ps.setInt(2, PAGE_SIZE);
              try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
          %>
          <tr data-id="<%=rs.getInt("id")%>"
              onclick="seleccionarFila(this)"
              ondblclick="vistaPrevia(getSelectedId())">
            <td><%= idx++ %></td>
            <td><%= rs.getString("titulo") %></td>
            <td><%= rs.getString("tipo") %></td>
            <td><%= rs.getString("area") %></td>
            <td><%= rs.getString("usuario_nombre")==null?"Desconocido":rs.getString("usuario_nombre") %></td>
            <td><%= rs.getTimestamp("fecha_creacion").toLocalDateTime().toLocalDate() %></td>
            <td><%= rs.getBoolean("requiere_respuesta")?"Requiere respuesta":"No aplica" %></td>
          </tr>
          <%        }
                }
            } catch(Exception e) {
              out.println("<tr><td colspan='7' style='color:red;'>Error cargando documentos.</td></tr>");
            }
          %>
        </tbody>
      </table>

      <ul class="pagination">
        <li class="<%= currentPage==1 ? "disabled" : "" %>"><a href="?page=1">&laquo;&laquo;</a></li>
        <li class="<%= currentPage==1 ? "disabled" : "" %>"><a href="?page=<%=currentPage-1%>">&laquo;</a></li>
        <% for(int p=startPage; p<=endPage; p++){
             boolean cur = (p==currentPage);
        %>
          <li class="<%= cur?"active":"" %>">
            <a href="?page=<%=p%>"><%=p%></a>
          </li>
        <% } %>
        <li class="<%= currentPage==totalPages ? "disabled" : "" %>"><a href="?page=<%=currentPage+1%>">&raquo;</a></li>
        <li class="<%= currentPage==totalPages ? "disabled" : "" %>"><a href="?page=<%=totalPages%>">&raquo;&raquo;</a></li>
      </ul>

      <section class="actions">
        <button onclick="vistaPreviaSeleccionado()">Vista previa</button>
        <% if (puedeEditarDocumento) { %>
          <button onclick="editarSeleccionado()">Editar</button>
        <% } %>
        <% if (permisosRol.contains(mapaPermisos.get("eliminar_documento"))){ %>
          <button onclick="eliminarSeleccionado()">Eliminar</button>
        <% } %>
        <button onclick="descargarSeleccionado()">Descargar</button>
      </section>
    </div>
  </div>

  <!-- Modal -->
  <div class="modal-overlay" id="modal">
    <div class="modal-content">
      <button class="modal-close" id="btnCloseModal">&times;</button>
      <iframe class="modal-iframe" id="modalIframe" src="about:blank"></iframe>
    </div>
  </div>

  <script>
    const ctx = '<%=request.getContextPath()%>',
          modal = document.getElementById('modal'),
          iframe = document.getElementById('modalIframe'),
          openBtn = document.getElementById('btnOpenModal'),
          closeBtn= document.getElementById('btnCloseModal');

    if(openBtn) openBtn.onclick = () => {
      iframe.src = ctx + '/adicionarDocumento.jsp';
      modal.style.display = 'flex';
    };
    closeBtn.onclick = () => {
      modal.style.display = 'none';
      iframe.src = 'about:blank';
    };
    window.onclick = e => { if (e.target === modal) closeBtn.onclick(); };

    function seleccionarFila(r){
      document.querySelectorAll('tr.selected').forEach(x=>x.classList.remove('selected'));
      r.classList.add('selected');
    }
    function getSelectedId(){
      let s = document.querySelector('tr.selected');
      return s ? s.dataset.id : null;
    }
    function vistaPrevia(id){
      if (!id) return alert('Selecciona un documento.');
      iframe.src = ctx + '/vistaPreviaDocumento.jsp?id=' + id;
      modal.style.display = 'flex';
    }
    function vistaPreviaSeleccionado(){ vistaPrevia(getSelectedId()); }
    function editarSeleccionado(){
      let id = getSelectedId();
      if (id) location.href = 'editarDocumento.jsp?id=' + id;
      else alert('Selecciona un documento.');
    }
    function eliminarSeleccionado(){
      let id = getSelectedId();
      if (id && confirm('¿Eliminar documento?'))
        location.href = 'eliminarDocumento.jsp?id=' + id;
    }
    function descargarSeleccionado(){
      let id = getSelectedId();
      if (id) window.open(ctx + '/descargarDocumento.jsp?id=' + id);
      else alert('Selecciona un documento.');
    }
    function filtrar(){
      let t = document.getElementById('filtro').value.toLowerCase();
      document.querySelectorAll('#tablaDocs tbody tr')
        .forEach(r => r.textContent.toLowerCase().includes(t)
                          ? r.style.display = ''
                          : r.style.display = 'none');
    }
    function limpiar(){
      document.getElementById('filtro').value = '';
      filtrar();
    }
  </script>
</body>
</html>
