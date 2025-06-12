<%@ page import="
    java.net.URLEncoder,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.SQLException,
    java.time.LocalDate,
    java.io.StringWriter,
    java.io.PrintWriter,
    java.util.HashSet,
    java.util.HashMap,
    java.util.Set,
    java.util.Optional,
    clasesGenericas.Usuario,
    clasesGenericas.Menu,
    clasesGenericas.RolPermiso,
    clasesGenericas.Permiso,
    ConexionBD.conexionBD
" %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ include file="menu.jsp" %>
<%
    String errorMsg = null;
    String infoMsg = null;

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
    int userId = usuario.getId();
    String pageFileName = request.getServletPath()
        .substring(request.getServletPath().lastIndexOf('/') + 1);
    Menu.recordUse(usuario.getId(), pageFileName);

    Set<Integer> permisoIds = new HashSet<>();
    Map<String,Integer> permisosMap = new HashMap<>();
    for (RolPermiso rp : RolPermiso.findByRolId(usuario.getRol().getId())) {
        permisoIds.add(rp.getPermisoId());
    }
    for (Permiso p : Permiso.findAll()) {
        permisosMap.put(p.getNombre(), p.getId());
    }
    boolean puedeVerPlantillas     = permisoIds.contains(permisosMap.get("ver_plantillas"));
    boolean puedeVerBusquedas      = permisoIds.contains(permisosMap.get("ver_busquedas"));
    boolean puedeSubirDocumento    = permisoIds.contains(permisosMap.get("crear_documento"));
    boolean puedeEditarDocumento   = permisoIds.contains(permisosMap.get("subir_version"));
    boolean puedeEliminarDocumento = permisoIds.contains(permisosMap.get("eliminar_documento"));

    final int PAGE_SIZE = 8;
    int currentPage = Optional.ofNullable(request.getParameter("page"))
        .flatMap(s->{try{return Optional.of(Integer.parseInt(s));}catch(Exception e){return Optional.empty();}})
        .orElse(1);
    if (currentPage < 1) currentPage = 1;

    String termParam = Optional.ofNullable(request.getParameter("term")).orElse("").trim();
    String exactParam = request.getParameter("exact");
    boolean exact = "true".equalsIgnoreCase(exactParam);
    String sqlTerm = exact ? termParam : "%" + termParam + "%";

    if (request.getParameter("errorMsg") != null) {
        errorMsg = request.getParameter("errorMsg");
    }
    if (request.getParameter("infoMsg") != null) {
        infoMsg = request.getParameter("infoMsg");
    }

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String deleteIdParam = request.getParameter("deleteId");
        if (deleteIdParam != null && puedeEliminarDocumento) {
            int docIdToDelete = -1;
            try {
                docIdToDelete = Integer.parseInt(deleteIdParam);
            } catch (NumberFormatException e) {
                docIdToDelete = -1;
            }
            if (docIdToDelete > 0) {
                try (Connection conn = conexionBD.conectar()) {
                    conn.setAutoCommit(false);
                    boolean ok = true;
                    try (PreparedStatement pstUpd = conn.prepareStatement(
                            "UPDATE documento SET eliminado = 1 WHERE id = ?"
                        )) {
                        pstUpd.setInt(1, docIdToDelete);
                        int updated = pstUpd.executeUpdate();
                        if (updated == 0) {
                            ok = false;
                        }
                    } catch (SQLException e) {
                        ok = false;
                        StringWriter sw = new StringWriter();
                        e.printStackTrace(new PrintWriter(sw));
                        System.err.println("Error al marcar eliminado documento: " + sw.toString());
                    }
                    if (ok) {
                        try (PreparedStatement pstIns = conn.prepareStatement(
                                "INSERT INTO papelera (doc_id) VALUES (?)"
                            )) {
                            pstIns.setInt(1, docIdToDelete);
                            pstIns.executeUpdate();
                        } catch (SQLException e) {
                            ok = false;
                            StringWriter sw = new StringWriter();
                            e.printStackTrace(new PrintWriter(sw));
                            System.err.println("Error al insertar en papelera: " + sw.toString());
                        }
                    }
                    if (ok) {
                        try (PreparedStatement pstAudit = conn.prepareStatement(
                                "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)"
                            )) {
                            pstAudit.setInt(1, userId);
                            pstAudit.setInt(2, docIdToDelete);
                            pstAudit.setString(3, "ELIMINAR_DOCUMENTO");
                            pstAudit.executeUpdate();
                        } catch (SQLException e) {
                            ok = false;
                            StringWriter sw = new StringWriter();
                            e.printStackTrace(new PrintWriter(sw));
                            System.err.println("Error al insertar en audit_log: " + sw.toString());
                        }
                    }
                    if (ok) {
                        conn.commit();
                        infoMsg = "Documento eliminado correctamente.";
                    } else {
                        conn.rollback();
                        errorMsg = "No se pudo eliminar el documento.";
                    }
                } catch (SQLException e) {
                    StringWriter sw = new StringWriter();
                    e.printStackTrace(new PrintWriter(sw));
                    System.err.println("Error en transacción de eliminación: " + sw.toString());
                    errorMsg = "Error al eliminar el documento.";
                }
            } else {
                errorMsg = "ID de documento inválido.";
            }
        } else if (deleteIdParam != null) {
            errorMsg = "No tienes permiso para eliminar.";
        }
        String redirectURL = request.getRequestURI() + "?page=" + currentPage;
        if (!termParam.isEmpty()) {
            redirectURL += "&term=" + URLEncoder.encode(termParam, "UTF-8");
            if (exact) {
                redirectURL += "&exact=true";
            }
        }
        if (infoMsg != null) {
            redirectURL += "&infoMsg=" + URLEncoder.encode(infoMsg, "UTF-8");
        }
        if (errorMsg != null) {
            redirectURL += "&errorMsg=" + URLEncoder.encode(errorMsg, "UTF-8");
        }
        response.sendRedirect(redirectURL);
        return;
    }

    int totalRows = 0;
    StringBuilder countSb = new StringBuilder()
        .append("SELECT COUNT(*) FROM documento d WHERE ")
        .append(puedeVerPlantillas
            ? "(d.recibido_por=? OR d.radicado_a=?)"
            : "d.es_plantilla=0 AND (d.recibido_por=? OR d.radicado_a=?)")
        .append(" AND d.eliminado=0");
    if (!termParam.isEmpty()) {
        countSb.append(exact ? " AND d.titulo = ?" : " AND d.titulo LIKE ?");
    }
    try (Connection c = conexionBD.conectar();
         PreparedStatement ps = c.prepareStatement(countSb.toString())) {
        int i=1;
        ps.setInt(i++, usuario.getId());
        ps.setInt(i++, usuario.getId());
        if (!termParam.isEmpty()) ps.setString(i++, sqlTerm);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) totalRows = rs.getInt(1);
        }
    } catch (SQLException e) {
        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        System.err.println("Error en COUNT documento: " + sw.toString());
        errorMsg = "Hubo un error al obtener el número de documentos.";
    }
    int totalPages = Math.max(1, (int)Math.ceil((double)totalRows/PAGE_SIZE));
    if (currentPage > totalPages) currentPage = totalPages;
    int windowSize = 3;
    int startPage = Math.max(1, currentPage - windowSize/2);
    int endPage = Math.min(totalPages, startPage + windowSize - 1);
    if (endPage - startPage < windowSize - 1) startPage = Math.max(1, endPage - windowSize + 1);

    StringBuilder sbQuery = new StringBuilder()
        .append("SELECT d.id,d.numero_radicado,d.titulo,d.tipo,a.nombre AS area,")
        .append("d.es_plantilla,d.recibido_por,d.radicado_a,")
        .append("d.requiere_respuesta,d.respondido,")
        .append("u_rem.nombre AS remitente,u_dest.nombre AS destinatario,d.fecha_creacion ")
        .append("FROM documento d ")
        .append("LEFT JOIN area a ON d.id_area=a.id ")
        .append("LEFT JOIN usuario u_rem ON d.recibido_por=u_rem.id ")
        .append("LEFT JOIN usuario u_dest ON d.radicado_a=u_dest.id ")
        .append("WHERE ")
        .append(puedeVerPlantillas
            ? "(d.recibido_por=? OR d.radicado_a=?)"
            : "d.es_plantilla=0 AND (d.recibido_por=? OR d.radicado_a=?)")
        .append(" AND d.eliminado=0");
    if (!termParam.isEmpty()) {
        sbQuery.append(exact ? " AND d.titulo = ?" : " AND d.titulo LIKE ?");
    }
    sbQuery.append(" ORDER BY d.fecha_creacion DESC LIMIT ?,?");
    String sql = sbQuery.toString();
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Gestión de Documentos</title>
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/fontawesome.css">
  <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

  <style>
    :root {
      --bg: #12121c;
      --accent: #007bff;
      --text: #eaeaea;
      --light: #fff;
      --shadow: rgba(0,0,0,0.5);
    }
    html, body {
      margin: 0; padding: 0; height: 100%; overflow-y: auto;
      background: var(--bg); color: var(--text);
      background: url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
    }
    * { box-sizing: border-box; font-family: 'Poppins', sans-serif; color: inherit; }

    .menu-container { max-width: 960px; margin: 20px auto; padding: 0 10px; }
    .menu-box { background: #fff; color: #000; padding: 16px;
                border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
    h2 { font-size:1.5rem; margin-bottom:14px; color:#333; }

    .toolbar { display:flex; flex-wrap:wrap; gap:6px; margin-bottom:14px; position:relative; }
    .toolbar input[type="text"] {
      flex:1; border:1px solid #ccc;
      font-size:0.9rem; padding:6px 10px; border-radius:4px;
    }
    .toolbar button {
      font-size:0.9rem; padding:6px 10px; border-radius:4px;
      background:var(--accent); color:#fff; border:none; cursor:pointer;
    }
    .toolbar button:hover { opacity:0.9; }

    .suggestions {
      position:absolute; top:40px; left:0; right:100px;
      background:#fff; border:1px solid #ccc; border-top:none;
      max-height:200px; overflow-y:auto; z-index:100;
    }
    .suggestion-item {
      padding:8px 10px; cursor:pointer; font-size:0.9rem; color:#333;
    }
    .suggestion-item:hover {
      background:#f0f0f0;
    }

    .docs-table { width:100%; border-collapse:collapse; margin-bottom:16px; }
    .docs-table th, .docs-table td {
      padding:10px 6px; border:1px solid #ddd; font-size:0.85rem; word-break:break-word;
    }
    .docs-table th { background:#f5f5f5; text-transform:uppercase; }
    .docs-table tr:hover { background:#efefef; cursor:pointer; }
    .docs-table tr.selected {
      background: rgba(0, 123, 255, 0.2) !important;
    }

    .pendiente { background:#ffeb99!important; color:#000!important; }
    .respondido { background:#89b4f8!important; color:#000!important; }

    .checkbox-label {
      display:inline-flex; align-items:center; gap:4px;
      font-size:0.85rem; cursor:pointer; user-select:none;
    }
    .checkbox-label input {
      width:16px; height:16px; margin:0;
    }

    .actions { display:flex; justify-content:flex-end; gap:6px; flex-wrap:wrap; }
    .actions button {
      font-size:0.85rem; padding:6px 12px; border-radius:4px;
      background:var(--accent); color:#fff; border:none; cursor:pointer;
    }
    .actions button:hover { opacity:0.9; }

    .btn-attach-response {
      font-size:0.8rem;
      padding:4px 8px;
      margin-top:4px;
      border-radius:4px;
      background:#28a745;
      color:#fff;
      border:none;
      cursor:pointer;
      display:inline-block;
    }
    .btn-attach-response:hover { opacity:0.9; }

    .modal-overlay {
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(0,0,0,0.5); display:none; align-items:center; justify-content:center; z-index:1000;
    }
    .modal-content {
      background:#fff; width:90%; max-width:760px; border-radius:6px; position:relative;
      box-shadow:0 4px 12px rgba(0,0,0,0.2);
    }
    .modal-close {
      position:absolute; top:10px; right:10px;
      background: var(--accent); color: #fff; border: none;
      padding: 8px; border-radius: 50%; font-size: 1.4rem; cursor: pointer;
    }
    .modal-close:hover {
      background: #0056b3;
    }
    .modal-iframe { width:100%; height:580px; border:none; border-radius:0 0 6px 6px; }

    .pagination {
      display:flex; justify-content:center; align-items:center;
      gap:8px; margin-top:20px; list-style:none; padding:0; flex-wrap:wrap;
    }
    .pagination li a {
      display:inline-block; background:var(--accent); color:#fff;
      text-decoration:none; padding:10px 16px; font-size:1rem;
      border-radius:4px; min-width:44px; text-align:center;
      transition:background 0.3s ease;
    }
    .pagination li.disabled a { background:#ccc; color:#666; pointer-events:none; }
    .pagination li.active a { background:#4e32a8; font-weight:bold; border:2px solid #fff; }
    .error-message {
      background: #f8d7da; color: #842029; padding: 10px; border:1px solid #f5c2c7;
      border-radius:4px; margin-bottom: 16px;
    }
    .info-message {
      background: #d1e7dd; color: #0f5132; padding: 10px; border:1px solid #badbcc;
      border-radius:4px; margin-bottom: 16px;
    }
  </style>
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
<div class="menu-container">
  <div class="menu-box">
    <h2>Gestión de Documentos</h2>

    <% if (errorMsg != null) { %>
      <div class="error-message">
        <strong>Error:</strong> <%= errorMsg %>
      </div>
    <% } %>
    <% if (infoMsg != null) { %>
      <div class="info-message">
        <strong>Info:</strong> <%= infoMsg %>
      </div>
    <% } %>

    <section class="toolbar">
      <% if (puedeSubirDocumento) { %>
        <button id="btnOpenModal"><i class="fas fa-upload"></i> Subir</button>
      <% } %>
      <% if (puedeVerBusquedas) { %>
        <input id="filtroTitulo" type="text" placeholder="Buscar por título…" autocomplete="off" value="<%=termParam%>">
        <div id="suggestions" class="suggestions"></div>
        <button id="btnBuscar"><i class="fas fa-search"></i> Buscar</button>
        <button id="btnLimpiar"><i class="fas fa-eraser"></i> Limpiar</button>
      <% } %>
    </section>

    <table id="tablaDocs" class="docs-table">
      <thead>
        <tr>
          <th>Número Radicado</th>
          <th>Nombre</th><th>Tipo</th><th>Área</th>
          <th>Remitente</th><th>Destinatario</th><th>Fecha</th>
          <th>Estado</th><th>Respondido</th><th>Acción</th>
        </tr>
      </thead>
      <tbody>
        <%
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            int i=1;
            ps.setInt(i++, usuario.getId());
            ps.setInt(i++, usuario.getId());
            if (!termParam.isEmpty()) ps.setString(i++, sqlTerm);
            ps.setInt(i++, (currentPage-1)*PAGE_SIZE);
            ps.setInt(i, PAGE_SIZE);
            try (ResultSet rs = ps.executeQuery()) {
              boolean anyRow = false;
              while (rs.next()) {
                anyRow = true;
                boolean esPlantilla= rs.getBoolean("es_plantilla");
                boolean soyRem= rs.getInt("recibido_por")==usuario.getId();
                boolean soyDest= rs.getInt("radicado_a")==usuario.getId();
                boolean reqR= rs.getBoolean("requiere_respuesta");
                boolean resp= rs.getBoolean("respondido");
                if (!(soyRem||soyDest)) continue;
                LocalDate f = rs.getTimestamp("fecha_creacion").toLocalDateTime().toLocalDate();
                int docId = rs.getInt("id");
        %>
        <tr data-id="<%=docId%>" onclick="seleccionarFila(this)">
          <td><%= Optional.ofNullable(rs.getString("numero_radicado")).orElse("-") %></td>
          <td><%= rs.getString("titulo") %></td>
          <td><%= rs.getString("tipo")+ (esPlantilla?" (plantilla)":"") %></td>
          <td><%= rs.getString("area") %></td>
          <td><%= rs.getString("remitente") %></td>
          <td>
            <% if (esPlantilla) out.print("No aplica");
               else { String d=rs.getString("destinatario"); out.print(d!=null?d:"No aplica"); } %>
          </td>
          <td><%= f %></td>
          <td><%= soyRem?"Enviado": (soyDest&&reqR?(resp?"Respondido":"Pendiente"):"—") %></td>
          <td class="<%= soyDest&&reqR&&!esPlantilla?(resp?"respondido":"pendiente"):"" %>">
            <% if (soyDest&&reqR&&!esPlantilla) { %>
            <label class="checkbox-label">
              <input type="checkbox" <%=resp?"checked":""%> onchange="toggleRespondido(<%=docId%>)">
              <i class="fas fa-check-circle"></i>
              <span><%= resp?"Marcado":"Marcar como respondido" %></span>
            </label>
            <% } else out.print("—"); %>
          </td>
          <td>
            <% if (soyDest&&reqR&&!esPlantilla) {
                 int resId=0; String path=null;
                 try (PreparedStatement pst2=c.prepareStatement(
                        "SELECT id,archivo_path FROM documento_respuesta WHERE documento_id=?")) {
                   pst2.setInt(1,docId);
                   try (ResultSet rs2=pst2.executeQuery()){
                     if(rs2.next()){resId=rs2.getInt("id");path=rs2.getString("archivo_path");}
                   }
                 } catch (SQLException e2) {
                   StringWriter sw2=new StringWriter();
                   e2.printStackTrace(new PrintWriter(sw2));
                   System.err.println("Error al obtener respuesta para docId=" + docId + ": " + sw2.toString());
                 }
                 if(path==null){ %>
            <button class="btn-attach-response" onclick="abrirAdjuntarRespuesta(<%=docId%>)">
              <i class="fas fa-paperclip"></i> Adjuntar
            </button>
            <% } else {
                String nombre = path.substring(path.lastIndexOf('/')+1); %>
            <span><i class="fas fa-file"></i> <%=nombre%></span>
            <button class="btn-attach-response" onclick="abrirEditarRespuesta(<%=resId%>)">
              <i class="fas fa-edit"></i>
            </button>
            <button class="btn-attach-response" onclick="previewRespuesta(<%=resId%>)">
              <i class="fas fa-eye"></i>
            </button>
            <a href="descargarRespuesta.jsp?id=<%=resId%>" class="btn-attach-response" target="_blank">
              <i class="fas fa-download"></i>
            </a>
            <% }
               } else out.print("—"); %>
          </td>
        </tr>
        <%
              }
              if (!anyRow) {
        %>
        <tr>
          <td colspan="10" style="text-align:center; color:#666;">
            No hay documentos para mostrar.
          </td>
        </tr>
        <%
              }
            }
        } catch (SQLException e) {
            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            System.err.println("Error en SELECT documentos: " + sw.toString());
        %>
        <tr>
          <td colspan="10" style="text-align:left; color:red;">
            Hubo un error al cargar los documentos.
          </td>
        </tr>
        <%
        }
        %>
      </tbody>
    </table>

    <ul class="pagination">
      <li class="<%=currentPage==1?"disabled":""%>">
        <a href="?page=1<%=termParam.isEmpty()?"":"&term="+URLEncoder.encode(termParam,"UTF-8")%>">&laquo;&laquo;</a>
      </li>
      <li class="<%=currentPage==1?"disabled":""%>">
        <a href="?page=<%=currentPage-1%><%=termParam.isEmpty()?"":"&term="+URLEncoder.encode(termParam,"UTF-8")%>">&laquo;</a>
      </li>
      <% for(int p=startPage;p<=endPage;p++){ %>
      <li class="<%=p==currentPage?"active":""%>">
        <a href="?page=<%=p%><%=termParam.isEmpty()?"":"&term="+URLEncoder.encode(termParam,"UTF-8")%>"><%=p%></a>
      </li>
      <% } %>
      <li class="<%=currentPage==totalPages?"disabled":""%>">
        <a href="?page=<%=currentPage+1%><%=termParam.isEmpty()?"":"&term="+URLEncoder.encode(termParam,"UTF-8")%>">&rsaquo;</a>
      </li>
      <li class="<%=currentPage==totalPages?"disabled":""%>">
        <a href="?page=<%=totalPages%><%=termParam.isEmpty()?"":"&term="+URLEncoder.encode(termParam,"UTF-8")%>">&raquo;&raquo;</a>
      </li>
    </ul>

    <section class="actions">
      <button onclick="vistaPreviaSeleccionado()"><i class="fas fa-eye"></i> Vista previa</button>
      <% if(puedeEditarDocumento){ %>
      <button onclick="editarSeleccionado()"><i class="fas fa-edit"></i> Editar</button>
      <% } %>
      <% if(puedeEliminarDocumento){ %>
      <button onclick="eliminarSeleccionado()"><i class="fas fa-trash"></i> Eliminar</button>
      <% } %>
      <button onclick="descargarSeleccionado()"><i class="fas fa-download"></i> Descargar</button>
    </section>
  </div>
</div>

<div id="modal" class="modal-overlay">
  <div class="modal-content">
    <button id="btnCloseModal" class="modal-close">&times;</button>
    <iframe id="modalIframe" class="modal-iframe"></iframe>
  </div>
</div>

<%-- Formulario oculto para eliminar vía POST --%>
<form id="deleteForm" method="post" action="documento.jsp" style="display:none;">
  <input type="hidden" name="deleteId" id="deleteIdInput" value=""/>
</form>

<script>
  const ctx = '<%=request.getContextPath()%>',
        modal = document.getElementById('modal'),
        iframe = document.getElementById('modalIframe'),
        openBtn = document.getElementById('btnOpenModal'),
        closeBtn = document.getElementById('btnCloseModal'),
        filtro = document.getElementById('filtroTitulo'),
        sugg = document.getElementById('suggestions'),
        btnBuscar = document.getElementById('btnBuscar'),
        btnLimpiar = document.getElementById('btnLimpiar');

  if(openBtn) openBtn.onclick = function(){
    iframe.src = ctx + '/adicionarDocumento.jsp';
    modal.style.display = 'flex';
  };
  closeBtn.onclick = function(){
    modal.style.display = 'none'; iframe.src = ''; window.location.reload();
  };
  window.onclick = function(e){ if(e.target===modal) closeBtn.onclick(); };

  filtro && filtro.addEventListener('input', function(){
    var term=this.value.trim();
    if(term.length<2){sugg.style.display='none';return;}
    fetch(ctx+'/buscarTitulos.jsp?term='+encodeURIComponent(term)+'&scope=documento')
      .then(r=>r.json())
      .then(json=>{
        sugg.innerHTML='';
        if(!json.length){sugg.style.display='none';return;}
        json.forEach(item=>{
          var d=document.createElement('div');
          d.className='suggestion-item';
          d.textContent=item.titulo+(item.tipo?' ('+item.tipo+')':'')+(item.esPlantilla?' (plantilla)':'');
          d.onmousedown=function(){
            filtro.value=item.titulo; sugg.style.display='none';
            window.location.href=ctx+'/documento.jsp?page=1&term='+encodeURIComponent(item.titulo)+'&exact=true';
          };
          sugg.appendChild(d);
        });
        sugg.style.display='block';
      })
      .catch(_=>sugg.style.display='none');
  });
  filtro && filtro.addEventListener('blur', function(){ setTimeout(()=>sugg.style.display='none',100); });

  btnBuscar && (btnBuscar.onclick=function(){
    var t=filtro.value.trim(), url=ctx+'/documento.jsp?page=1';
    if(t) url+='&term='+encodeURIComponent(t);
    window.location.href=url;
  });
  btnLimpiar && (btnLimpiar.onclick=function(){ window.location.href=ctx+'/documento.jsp'; });

  function seleccionarFila(r){
    document.querySelectorAll('#tablaDocs tbody tr.selected').forEach(x=>x.classList.remove('selected'));
    r.classList.add('selected');
  }
  function getSelectedId(){
    var s=document.querySelector('#tablaDocs tbody tr.selected');
    return s?s.dataset.id:null;
  }
  function toggleRespondido(id){
    fetch('marcarRespondido.jsp?id='+id,{method:'POST'})
      .then(r=>{if(r.ok) window.location.reload();else alert('Error');})
      .catch(_=>alert('Error'));
  }
  function vistaPreviaSeleccionado(){
    var id=getSelectedId(); if(!id)return alert('Selecciona un documento.');
    iframe.src=ctx+'/vistaPreviaDocumento.jsp?id='+id; modal.style.display='flex';
  }
  function editarSeleccionado(){
    var id=getSelectedId(); if(!id)return alert('Selecciona un documento.');
    window.location.href=ctx+'/editarDocumento.jsp?id='+id;
  }
  function eliminarSeleccionado(){
    var id=getSelectedId(); if(!id)return alert('Selecciona un documento.');
    if(confirm('¿Eliminar?')) {
      // Usar formulario POST
      document.getElementById('deleteIdInput').value = id;
      document.getElementById('deleteForm').submit();
    }
  }
  function descargarSeleccionado(){
    var id=getSelectedId(); if(!id)return alert('Selecciona un documento.');
    window.open(ctx+'/descargarDocumento.jsp?id='+id,'_blank');
  }
  function abrirAdjuntarRespuesta(docId){
    iframe.src=ctx+'/subirRespuesta.jsp?documentoId='+docId; modal.style.display='flex';
  }
  function abrirEditarRespuesta(resId){
    iframe.src=ctx+'/editarRespuesta.jsp?id='+resId; modal.style.display='flex';
  }
  function previewRespuesta(resId){
    iframe.src=ctx+'/vistaPreviaRespuesta.jsp?id='+resId; modal.style.display='flex';
  }
</script>
</body>
</html>
