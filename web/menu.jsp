<%@page import="java.net.URLDecoder, java.net.URLEncoder"%>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.sql.Timestamp,
    java.text.SimpleDateFormat,
    java.util.*,
    javax.servlet.http.Cookie,
    clasesGenericas.Usuario,
    clasesGenericas.RolPermiso,
    clasesGenericas.Permiso,
    clasesGenericas.Menu,
    ConexionBD.conexionBD
" %>
<%
    Object userAttr = session.getAttribute("user");
    Usuario usuarioObj = null;
    if (userAttr instanceof Usuario) {
        usuarioObj = (Usuario) userAttr;
    } else if (userAttr instanceof String) {
        String username = (String) userAttr;
        usuarioObj = Usuario.findByUsuario(username);
        if (usuarioObj != null) {
            session.setAttribute("user", usuarioObj);
        }
    }
    if (usuarioObj == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String servletPath = request.getServletPath();
    String jspName = servletPath.substring(servletPath.lastIndexOf('/') + 1);
    Menu.recordUse(usuarioObj.getId(), jspName);

    String usuarioNombre = usuarioObj.getUsuario();
    int rolId = usuarioObj.getRol().getId();
    Set<Integer> permisosRol = new HashSet<>();
    for (RolPermiso rp : RolPermiso.findByRolId(rolId)) {
        permisosRol.add(rp.getPermisoId());
    }
    Map<String,Integer> mapaPermisos = new HashMap<>();
    for (Permiso p : Permiso.findAll()) {
        mapaPermisos.put(p.getNombre(), p.getId());
    }
    Integer pid;

    SimpleDateFormat isoFmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
    isoFmt.setTimeZone(TimeZone.getTimeZone("UTC"));

    String seenTimeStr = null;
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie c : cookies) {
            if ("docSeenTime".equals(c.getName())) {
                seenTimeStr = c.getValue();
                break;
            }
        }
    }

    Timestamp lastSeenTimestamp;
    boolean firstVisit = false;
    if (seenTimeStr == null) {
        lastSeenTimestamp = new Timestamp(System.currentTimeMillis());
        String encodedDate = URLEncoder.encode(isoFmt.format(lastSeenTimestamp), "UTF-8");
        Cookie newCookie = new Cookie("docSeenTime", encodedDate);
        newCookie.setMaxAge(60 * 60 * 24 * 30);
        response.addCookie(newCookie);
        firstVisit = true;
    } else {
        try {
            String decoded = URLDecoder.decode(seenTimeStr, "UTF-8");
            java.util.Date parsed = isoFmt.parse(decoded);
            lastSeenTimestamp = new Timestamp(parsed.getTime());
        } catch (Exception ex) {
            lastSeenTimestamp = new Timestamp(System.currentTimeMillis());
        }
    }

    if ("true".equals(request.getParameter("clearSeen"))) {
        Timestamp nowTs = new Timestamp(System.currentTimeMillis());
        String encodedNow = URLEncoder.encode(isoFmt.format(nowTs), "UTF-8");
        Cookie resetCookie = new Cookie("docSeenTime", encodedNow);
        resetCookie.setMaxAge(60 * 60 * 24 * 30);
        response.addCookie(resetCookie);
        response.sendRedirect(request.getRequestURI());
        return;
    }

    int nuevosCount = 0;
    try (Connection conn = conexionBD.conectar()) {
        String sql =
            "SELECT COUNT(*) AS cnt " +
            "FROM documento " +
            "WHERE radicado_a = ? " +
            "  AND es_plantilla = 0 " +
            "  AND eliminado = 0 " +
            "  AND fecha_creacion >= ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, usuarioObj.getId());
            ps.setTimestamp(2, lastSeenTimestamp);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    nuevosCount = rs.getInt("cnt");
                }
            }
        }
    } catch (Exception e) {
        nuevosCount = 0;
    }
%>

<% if (!firstVisit && nuevosCount > 0) { %>
    <div id="globalBanner" style="
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          background-color: #fffae6;
          border-bottom: 1px solid #ffd700;
          padding: 12px 20px;
          z-index: 2000;
          color: #333;
          font-weight: bold;
          display: flex;
          align-items: center;
          justify-content: space-between;
        ">
        <div style="display:flex; align-items:center; gap:8px;">
            <i class="fas fa-info-circle" style="color:#ffd700;"></i>
            <span>Has recibido <%= nuevosCount %> documento(s) nuevo(s).</span>
        </div>
        <div style="display:flex; align-items:center; gap:16px;">
            <form method="post" style="margin:0;">
                <input type="hidden" name="clearSeen" value="true"/>
                <button type="submit" style="
                    background: none;
                    border: 1px solid #333;
                    padding: 4px 8px;
                    cursor: pointer;
                    font-size: 0.9rem;
                ">Marcar todo como vistos</button>
            </form>
            <span id="closeBanner" style="
                  cursor: pointer;
                  font-size: 1.2rem;
                  font-weight: bold;
                  padding: 0 8px;
                ">&times;</span>
        </div>
    </div>
    <div style="height: 60px;"></div>

    <script>
      document.getElementById('closeBanner').addEventListener('click', function() {
        document.getElementById('globalBanner').style.display = 'none';
      });
    </script>
<% } %>

<link rel="stylesheet" href="css/fontawesome.css">
<link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

<style>
 html, body { height: 100%; overflow-y: auto; margin:0; padding:0; }
 :root {
   --bg: #1f1f2e;
   --accent: #9d7aed;
   --text: #e0e0e0;
   --light: #ffffff;
   --shadow: rgba(0,0,0,0.4);
 }
 * { margin:0; padding:0; box-sizing:border-box; }
 a { color: inherit; text-decoration:none; }
 .menu-godness { position: relative; font-family: 'Poppins', sans-serif; }
 .hamburger {
   position: fixed; top:20px; left:20px; width:32px; height:32px;
   display:flex; flex-direction:column; justify-content:space-between;
   cursor:pointer; z-index:1001;
 }
 .hamburger span {
   display:block; height:4px; background:var(--light);
   border-radius:2px; transition: all .3s ease;
 }
 #toggle-menu { display:none; }
 #toggle-menu:checked ~ .hamburger span:nth-child(1) {
   transform:translateY(14px) rotate(45deg);
 }
 #toggle-menu:checked ~ .hamburger span:nth-child(2) { opacity:0; }
 #toggle-menu:checked ~ .hamburger span:nth-child(3) {
   transform:translateY(-14px) rotate(-45deg);
 }
 .sidebar {
   position:fixed; top:10%; left:-280px;
   width:280px; height:80%; background:var(--bg);
   padding:60px 20px 20px; box-shadow:4px 0 12px var(--shadow);
   transition:left .4s cubic-bezier(0.68,-0.55,0.27,1.55);
   z-index:1000; overflow-y:auto;
 }
 #toggle-menu:checked ~ .sidebar { left:0; }
 .user-info { display:flex; align-items:center; gap:12px; margin-bottom:24px; }
 .avatar {
   width:40px; height:40px; border-radius:50%;
   border:2px solid var(--accent);
   background: var(--light) url('images/avatar.png') center/cover no-repeat;
   display:flex; align-items:center; justify-content:center;
   color: var(--accent);
   font-size: 1.2rem;
 }
 .username { font-size:1rem; color:var(--light); font-weight:600; }
 .nav-list { list-style:none; display:flex; flex-direction:column; gap:12px; }
 .nav-list li a {
   display:flex; align-items:center; gap:10px;
   padding:8px 12px; color:var(--text);
   border-radius:6px; transition: background .2s, transform .2s;
 }
 .nav-list li a:hover {
   background:rgba(157,122,237,0.2);
   transform:translateX(3px);
 }
 .has-submenu > a { justify-content:space-between; }
 .arrow { transition:transform .3s; }
 .has-submenu:hover .arrow,
 .has-submenu:focus-within .arrow { transform:rotate(180deg); }
 .submenu {
   max-height:0; overflow:hidden; list-style:none;
   display:flex; flex-direction:column; gap:8px; margin-top:6px;
   transition:max-height .3s, opacity .3s; opacity:0;
 }
 .has-submenu:hover .submenu,
 .has-submenu:focus-within .submenu {
   max-height:300px; opacity:1;
 }
 .submenu li a {
   padding-left:32px; font-size:0.9rem;
   background:rgba(255,255,255,0.05);
 }
 .submenu li a:hover { background:rgba(157,122,237,0.25); }
 .sidebar, .menu-godness {
   opacity: 1 !important;
   background-color: var(--bg) !important;
 }
 body {
   background-color: initial !important;
   background-blend-mode: initial !important;
 }
</style>

<div class="menu-godness">
  <input type="checkbox" id="toggle-menu">
  <label for="toggle-menu" class="hamburger">
    <span></span><span></span><span></span>
  </label>
  <div class="sidebar">
    <div class="user-info">
      <div class="avatar">
        <i class="fas fa-user"></i>
      </div>
      <span class="username"><%= usuarioNombre %></span>
    </div>
    <ul class="nav-list">
      <%  %>
      <li><a href="inicio.jsp"><i class="fas fa-home"></i> Inicio</a></li>
      <%  %>
      <%
         pid = mapaPermisos.get("ver_documentos");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="documento.jsp"><i class="fas fa-file-alt"></i> Documentos</a></li>
      <% } %>
      <%
         pid = mapaPermisos.get("ver_plantillas");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="documentoPlantilla.jsp"><i class="fas fa-file-alt"></i> Plantillas</a></li>
      <% } %>
      <%
         pid = mapaPermisos.get("ver_busquedas");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="buscarDocumento.jsp"><i class="fas fa-search"></i> Búsquedas</a></li>
      <% } %>
      <%
         pid = mapaPermisos.get("ver_versiones");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="versionDocumento.jsp"><i class="fas fa-code-branch"></i> Versiones</a></li>
      <% } %>
      <%
         pid = mapaPermisos.get("ver_papelera");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="papelera.jsp"><i class="fas fa-trash"></i> Papelera</a></li>
      <% } %>
      <%
         pid = mapaPermisos.get("ver_auditoria");
         if (pid != null && permisosRol.contains(pid)) {
      %>
      <li><a href="auditoria.jsp"><i class="fas fa-clipboard-list"></i> Auditoría</a></li>
      <% } %>
      <%  %>
      <%
         Integer pUsr  = mapaPermisos.get("gestionar_usuarios");
         Integer pRol  = mapaPermisos.get("gestionar_roles");
         Integer pEtq  = mapaPermisos.get("gestionar_etiquetas");
         Integer pPerm = mapaPermisos.get("gestionar_permisos");
         Integer pArea = mapaPermisos.get("agregar_area");
         Integer pAsign= mapaPermisos.get("asignar_area");
         boolean anyConfig = false;
         if ((pUsr != null && permisosRol.contains(pUsr)) ||
             (pRol != null && permisosRol.contains(pRol)) ||
             (pEtq != null && permisosRol.contains(pEtq)) ||
             (pPerm!= null && permisosRol.contains(pPerm))||
             (pArea!= null && permisosRol.contains(pArea))||
             (pAsign!= null && permisosRol.contains(pAsign))) {
             anyConfig = true;
         }
         if (anyConfig) {
      %>
      <li class="has-submenu">
        <a href="#"><i class="fas fa-gear"></i> Configuración <i class="fas fa-chevron-down arrow"></i></a>
        <ul class="submenu">
          <% if (pUsr  != null && permisosRol.contains(pUsr))  { %>
            <li><a href="usuario.jsp"><i class="fas fa-users-cog"></i> Usuarios</a></li>
          <% } %>
          <% if (pRol  != null && permisosRol.contains(pRol))  { %>
            <li><a href="rol.jsp"><i class="fas fa-user-tag"></i> Roles</a></li>
          <% } %>
          <% if (pEtq != null && permisosRol.contains(pEtq)) { %>
            <li><a href="etiqueta.jsp"><i class="fas fa-tag"></i> Etiquetas</a></li>
          <% } %>
          <% if (pArea != null && permisosRol.contains(pArea)) { %>
            <li><a href="area.jsp"><i class="fas fa-building"></i> Área</a></li>
          <% } %>
          <% if (pAsign!= null && permisosRol.contains(pAsign)) { %>
            <li><a href="asignarArea.jsp"><i class="fas fa-map-marker-alt"></i> Asignar Área</a></li>
          <% } %>
          <% if (pPerm != null && permisosRol.contains(pPerm)) { %>
            <li><a href="permiso.jsp"><i class="fas fa-key"></i> Permisos</a></li>
          <% } %>
        </ul>
      </li>
      <% } %>
      <% %>
      <li><a href="cerrarSesion.jsp"><i class="fas fa-sign-out-alt"></i> Cerrar sesión</a></li>
    </ul>
  </div>
</div>
