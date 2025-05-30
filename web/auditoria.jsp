<%@ page import="
    java.sql.*,
    java.util.*,
    java.text.SimpleDateFormat,
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

    String nombre     = request.getParameter("nombre");
    String usuarioId  = request.getParameter("usuario");
    String accion     = request.getParameter("accion");
    String fechaDesde = request.getParameter("fechaDesde");
    String fechaHasta = request.getParameter("fechaHasta");
    int pagina = 1;
    try {
        pagina = Integer.parseInt(request.getParameter("pagina"));
        if (pagina < 1) pagina = 1;
    } catch (Exception e) { pagina = 1; }

    int limite = 10;
    int offset = (pagina - 1) * limite;

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss a");

    List<Map<String,Object>> usuarios = new ArrayList<>();
    try (Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=America/Bogota",
            "root","admin");
         Statement st = con.createStatement();
         ResultSet rsUsuarios = st.executeQuery("SELECT id, nombre FROM usuario")) {
        while (rsUsuarios.next()) {
            Map<String,Object> u = new HashMap<>();
            u.put("id",     rsUsuarios.getInt("id"));
            u.put("nombre", rsUsuarios.getString("nombre"));
            usuarios.add(u);
        }
    }

    StringBuilder sqlBase = new StringBuilder(
        "FROM audit_log al " +
        "JOIN usuario u ON al.usuario_id=u.id " +
        "JOIN documento d ON al.documento_id=d.id WHERE 1=1"
    );
    List<Object> params = new ArrayList<>();
    if (nombre != null && !nombre.trim().isEmpty()) {
        sqlBase.append(" AND d.titulo LIKE ?");
        params.add("%" + nombre.trim() + "%");
    }
    if (usuarioId != null && !"todos".equals(usuarioId)) {
        sqlBase.append(" AND u.id=?");
        params.add(Integer.valueOf(usuarioId));
    }
    if (accion != null && !"todos".equals(accion)) {
        sqlBase.append(" AND al.accion=?");
        params.add(accion);
    }
    if (fechaDesde != null && !fechaDesde.isEmpty()) {
        sqlBase.append(" AND al.timestamp>=?");
        params.add(fechaDesde + " 00:00:00");
    }
    if (fechaHasta != null && !fechaHasta.isEmpty()) {
        sqlBase.append(" AND al.timestamp<=?");
        params.add(fechaHasta + " 23:59:59");
    }

    int totalRegistros = 0;
    try (Connection con = DriverManager.getConnection(
             "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=America/Bogota",
             "root","admin");
         PreparedStatement pstCount = con.prepareStatement("SELECT COUNT(*) " + sqlBase.toString())) {
        for (int i = 0; i < params.size(); i++) {
            pstCount.setObject(i+1, params.get(i));
        }
        try (ResultSet rsCount = pstCount.executeQuery()) {
            if (rsCount.next()) totalRegistros = rsCount.getInt(1);
        }
    }
    int totalPaginas = (int) Math.ceil(totalRegistros / (double)limite);

    List<Map<String,String>> logs = new ArrayList<>();
    try (Connection con = DriverManager.getConnection(
             "jdbc:mysql://localhost:3306/gestion_documental?useSSL=false&serverTimezone=America/Bogota",
             "root","admin");
         PreparedStatement pstLogs = con.prepareStatement(
             "SELECT u.nombre AS usuario, d.titulo AS documento, al.accion, al. timestamp " +
             sqlBase.toString() + " ORDER BY al.timestamp DESC LIMIT ? OFFSET ?")) {

        for (int i = 0; i < params.size(); i++) {
            pstLogs.setObject(i+1, params.get(i));
        }
        pstLogs.setInt(params.size()+1, limite);
        pstLogs.setInt(params.size()+2, offset);

        try (ResultSet rsLogs = pstLogs.executeQuery()) {
            while (rsLogs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("usuario",   rsLogs.getString("usuario"));
                r.put("documento", rsLogs.getString("documento"));
                r.put("accion",    rsLogs.getString("accion"));
                Timestamp ts = rsLogs.getTimestamp("timestamp");
                r.put("fechaHora", ts != null ? sdf.format(ts) : "");
                logs.add(r);
            }
        }
    }

    int startPage = Math.max(1, pagina-1);
    int endPage   = Math.min(totalPaginas, startPage+2);
    if (endPage - startPage < 2) startPage = Math.max(1, endPage-2);
%>

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Auditoría</title>
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

    :root { --accent:#9d7aed; --input-bg:#f8f9fa; --hover-row:#f0f0f0; }
    body, * { font-family:Poppins,sans-serif; box-sizing:border-box; }
    .menu-container { max-width:1000px; margin:40px auto; padding:0 20px; }
    .menu-box { background:#fff; padding:24px; border-radius:8px;
               box-shadow:0 6px 20px rgba(0,0,0,0.15); }
    .toolbar-row { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:16px; }
    .toolbar-row input, .toolbar-row select {
      padding:8px; border:1px solid #ccc; border-radius:4px;
      background:var(--input-bg); flex:1; min-width:160px;
    }
    .toolbar-row button {
      padding:6px 14px; border:1px solid #000; cursor:pointer; transition:.2s;
    }
    .toolbar-row button:hover { background:#000; color:#fff; }
    .docs-table { width:100%; border-collapse:collapse; margin-top:20px; }
    .docs-table th, .docs-table td {
      padding:10px; border:1px solid #e0e0e0; text-align:left;
    }
    .docs-table th { background:#f1f1f1; text-transform:uppercase; }
    .docs-table tr:hover { background:var(--hover-row); }
    .pagination { display:flex; justify-content:center; gap:8px; margin-top:20px; }
    .pagination button {
      padding:10px 16px; border:none; border-radius:4px;
      background:var(--accent); color:#fff; cursor:pointer;
    }
    .pagination button[disabled] { background:#ccc; cursor:default; }
    .pagination .current { background:#4e32a8; font-weight:bold; }
  </style>
</head>
<body>
  <div class="menu-container">
    <div class="menu-box">
      <h2>Auditoría</h2>

      <% if (puedeBuscar) { %>
        <div class="toolbar-row">
          <input type="text" id="nombre" placeholder="Nombre documento"
                 value="<%= nombre!=null?nombre:"" %>">
          <button onclick="buscar()"><i class="fas fa-search"></i> Buscar</button>
        </div>
        <div class="toolbar-row">
          <select id="usuario">
            <option value="todos">Usuario: todos</option>
            <% for (Map<String,Object> u : usuarios) { %>
              <option value="<%=u.get("id")%>"
                <%= usuarioId!=null&&usuarioId.equals(u.get("id").toString())?"selected":"" %>>
                <%=u.get("nombre")%>
              </option>
            <% } %>
          </select>
          <select id="accion">
            <option value="todos">Acción: todos</option>
            <% Set<String> accionesSet=new LinkedHashSet<>(); 
               for(Map<String,String> r:logs) accionesSet.add(r.get("accion"));
               for(String a:accionesSet){ %>
              <option value="<%=a%>"
                <%= accion!=null&&accion.equals(a)?"selected":"" %>>
                <%=a%>
              </option>
            <% } %>
          </select>
          <input type="date" id="fechaDesde" value="<%=fechaDesde!=null?fechaDesde:"" %>">
          <input type="date" id="fechaHasta" value="<%=fechaHasta!=null?fechaHasta:"" %>">
          <button onclick="filtrar()"><i class="fas fa-filter"></i> Filtrar</button>
          <button onclick="limpiar()"><i class="fas fa-eraser"></i> Limpiar</button>
        </div>
      <% } %>

      <table class="docs-table">
        <thead>
          <tr>
            <th>Usuario</th><th>Documento</th><th>Acción</th><th>Fecha / Hora</th>
          </tr>
        </thead>
        <tbody>
          <% if (logs.isEmpty()) { %>
            <tr><td colspan="4" style="text-align:center">No hay registros</td></tr>
          <% } else {
               for(Map<String,String> r:logs){ %>
            <tr>
              <td><%=r.get("usuario")%></td>
              <td><%=r.get("documento")%></td>
              <td><%=r.get("accion")%></td>
              <td><%=r.get("fechaHora")%></td>
            </tr>
          <% } } %>
        </tbody>
      </table>

      <div class="pagination">
        <a href="auditoria.jsp?pagina=1
           <%= nombre!=null?"&nombre="+java.net.URLEncoder.encode(nombre,"UTF-8"):"" %>
           <%= usuarioId!=null?"&usuario="+usuarioId:"" %>
           <%= accion!=null?"&accion="+accion:"" %>
           <%= fechaDesde!=null?"&fechaDesde="+fechaDesde:"" %>
           <%= fechaHasta!=null?"&fechaHasta="+fechaHasta:"" %>">
          <button <%=pagina==1?"disabled":""%>>«</button>
        </a>
        <% for(int i=startPage;i<=endPage;i++){
             String url="auditoria.jsp?pagina="+i
               +(nombre!=null?"&nombre="+java.net.URLEncoder.encode(nombre,"UTF-8"):"")
               +(usuarioId!=null?"&usuario="+usuarioId:"")
               +(accion!=null?"&accion="+accion:"")
               +(fechaDesde!=null?"&fechaDesde="+fechaDesde:"")
               +(fechaHasta!=null?"&fechaHasta="+fechaHasta:""); %>
          <a href="<%=url%>">
            <button class="<%=i==pagina?"current":""%>"><%=i%></button>
          </a>
        <% } %>
        <a href="auditoria.jsp?pagina=<%=totalPaginas%>
           <%= nombre!=null?"&nombre="+java.net.URLEncoder.encode(nombre,"UTF-8"):"" %>
           <%= usuarioId!=null?"&usuario="+usuarioId:"" %>
           <%= accion!=null?"&accion="+accion:"" %>
           <%= fechaDesde!=null?"&fechaDesde="+fechaDesde:"" %>
           <%= fechaHasta!=null?"&fechaHasta="+fechaHasta:"" %>">
          <button <%=pagina==totalPaginas?"disabled":""%>>»</button>
        </a>
      </div>
    </div>
  </div>

  <script>
    function buscar() {
      const n=encodeURIComponent(document.getElementById('nombre').value.trim());
      const p=new URLSearchParams(location.search);
      if(n)p.set('nombre',n);else p.delete('nombre');
      location.href='auditoria.jsp?'+p;
    }
    function filtrar(){
      const p=new URLSearchParams();
      ['usuario','accion','fechaDesde','fechaHasta'].forEach(id=>{
        const v=document.getElementById(id).value;
        if(v&&v!=='todos')p.set(id,v);
      });
      const n=document.getElementById('nombre').value.trim();
      if(n)p.set('nombre',n);
      location.href='auditoria.jsp?'+p;
    }
    function limpiar(){ location.href='auditoria.jsp'; }
  </script>
</body>
</html>
