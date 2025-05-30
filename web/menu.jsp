<%@page import="clasesGenericas.Menu"%>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.*,
    clasesGenericas.Usuario,
    clasesGenericas.RolPermiso,
    clasesGenericas.Permiso,
    clasesGenericas.Menu
" %>

<%
    String servletPath = request.getServletPath();                      
    String jspName     = servletPath.substring(servletPath.lastIndexOf('/') + 1);
    Menu.recordUse(jspName);

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
%>

<link rel="stylesheet" href="css/fontawesome.css">

<style>
  html, body { height: 100%; overflow-y: auto; }
  :root {
    --bg: #1f1f2e; --accent: #9d7aed; --text: #e0e0e0;
    --light: #ffffff; --shadow: rgba(0,0,0,0.4);
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  a { color: inherit; text-decoration:none; }
  .menu-godness { position: relative; font-family: 'Poppins', sans-serif; }
  .hamburger { position: fixed; top:20px; left:20px; width:32px; height:32px;
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
      <div class="avatar"></div>
      <span class="username"><%= usuarioNombre %></span>
    </div>
    <ul class="nav-list">
      <% pid = mapaPermisos.get("ver_inicio");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="inicio.jsp"><i class="fas fa-home"></i> Inicio</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_documentos");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="documento.jsp"><i class="fas fa-file-alt"></i> Documentos</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_plantillas");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="documentoPlantilla.jsp"><i class="fas fa-file-alt"></i> Plantillas</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_busquedas");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="buscarDocumento.jsp"><i class="fas fa-search"></i> Búsquedas</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_versiones");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="versionDocumento.jsp"><i class="fas fa-code-branch"></i> Versiones</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_papelera");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="papelera.jsp"><i class="fas fa-trash"></i> Papelera</a></li>
      <% } %>
      <% pid = mapaPermisos.get("ver_auditoria");
         if (pid != null && permisosRol.contains(pid)) { %>
        <li><a href="auditoria.jsp"><i class="fas fa-clipboard-list"></i> Auditoría</a></li>
      <% } %>

      <% 
         Integer pConf   = mapaPermisos.get("ver_configuracion"),
                 pUsr    = mapaPermisos.get("gestionar_usuarios"),
                 pRol    = mapaPermisos.get("gestionar_roles"),
                 pEtq    = mapaPermisos.get("gestionar_etiquetas"),
                 pPerm   = mapaPermisos.get("gestionar_permisos"),
                 pPref   = mapaPermisos.get("editar_preferencias"),
                 pArea   = mapaPermisos.get("agregar_area"),
                 pAsign  = mapaPermisos.get("asignar_area");
         if ((pConf!=null && permisosRol.contains(pConf))
          || (pUsr!=null  && permisosRol.contains(pUsr))
          || (pRol!=null  && permisosRol.contains(pRol))
          || (pEtq!=null && permisosRol.contains(pEtq))
          || (pArea!=null&& permisosRol.contains(pArea))
          || (pAsign!=null&& permisosRol.contains(pAsign))
          || (pPerm!=null&& permisosRol.contains(pPerm))
          || (pPref!=null&& permisosRol.contains(pPref))) {
      %>
        <li class="has-submenu">
          <a href="#"><i class="fas fa-gear"></i> Configuración <i class="fas fa-chevron-down arrow"></i></a>
          <ul class="submenu">
            <% if (pUsr!=null  && permisosRol.contains(pUsr))  { %>
              <li><a href="usuario.jsp"><i class="fas fa-users-cog"></i> Usuarios</a></li>
            <% } %>
            <% if (pRol!=null  && permisosRol.contains(pRol))  { %>
              <li><a href="rol.jsp"><i class="fas fa-user-tag"></i> Roles</a></li>
            <% } %>
            <% if (pEtq!=null && permisosRol.contains(pEtq)) { %>
              <li><a href="etiqueta.jsp"><i class="fas fa-tag"></i> Etiquetas</a></li>
            <% } %>
            <% if (pArea!=null && permisosRol.contains(pArea)) { %>
              <li><a href="area.jsp"><i class="fas fa-building"></i> Área</a></li>
            <% } %>
            <% if (pAsign!=null && permisosRol.contains(pAsign)) { %>
              <li><a href="asignarArea.jsp"><i class="fas fa-map-marker-alt"></i> Asignar Área</a></li>
            <% } %>
            <% if (pPerm!=null&& permisosRol.contains(pPerm)) { %>
              <li><a href="permiso.jsp"><i class="fas fa-key"></i> Permisos</a></li>
            <% } %>
            <% if (pPref!=null&& permisosRol.contains(pPref)) { %>
              <li><a href="preferencia.jsp"><i class="fas fa-sliders-h"></i> Preferencias</a></li>
            <% } %>
          </ul>
        </li>
      <% } %>

      <% pid = mapaPermisos.get("cerrar_sesion");
         if (pid!=null && permisosRol.contains(pid)) { %>
        <li><a href="cerrarSesion.jsp"><i class="fas fa-sign-out-alt"></i> Cerrar sesión</a></li>
      <% } %>
    </ul>
  </div>
</div>
