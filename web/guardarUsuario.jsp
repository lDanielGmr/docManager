<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="clasesGenericas.Usuario, clasesGenericas.Rol, java.net.URLEncoder" %>
<%
    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("usuario.jsp");
        return;
    }

    String accion = request.getParameter("accion"); 
    String idStr = request.getParameter("id"); 

    if ("eliminar".equalsIgnoreCase(accion)) {
        String mensajeDel = null;
        boolean errorDel = false;
        if (idStr == null || idStr.trim().isEmpty()) {
            errorDel = true;
            mensajeDel = "ID de usuario no proporcionado para eliminación.";
        }
        if (!errorDel) {
            try {
                int id = Integer.parseInt(idStr.trim());
                Usuario uDel = Usuario.findAll().stream()
                        .filter(x -> x.getId() == id)
                        .findFirst().orElse(null);
                if (uDel == null) {
                    errorDel = true;
                    mensajeDel = "Usuario a eliminar no encontrado.";
                } else {
                    try {
                        uDel.delete();
                        mensajeDel = "Usuario eliminado correctamente.";
                    } catch (Exception ex) {
                        errorDel = true;
                        mensajeDel = "Error al eliminar el usuario: " + ex.getMessage();
                    }
                }
            } catch (NumberFormatException e) {
                errorDel = true;
                mensajeDel = "ID de usuario inválido.";
            }
        }
        String destinoDel = "usuario.jsp";
        if (mensajeDel != null) {
            destinoDel += "?msg=" + URLEncoder.encode(mensajeDel, "UTF-8");
            if (errorDel) {
                destinoDel += "&error=1";
            }
        }
        response.sendRedirect(destinoDel);
        return;
    }

    String nombre = request.getParameter("nombre");
    String usuarioParam = request.getParameter("usuario");
    String contrasena = request.getParameter("contrasena");
    String rolParam = request.getParameter("rol");
    String areaParam = request.getParameter("area");

    String mensaje = null;
    boolean error = false;

    if (nombre == null || nombre.trim().isEmpty()
        || usuarioParam == null || usuarioParam.trim().isEmpty()
        || rolParam == null || rolParam.trim().isEmpty()
    ) {
        error = true;
        mensaje = "Faltan campos obligatorios.";
    }

    Usuario u = null;
    boolean esEdicion = false;
    if (!error && idStr != null && !idStr.trim().isEmpty()) {
        try {
            int id = Integer.parseInt(idStr.trim());
            u = Usuario.findAll().stream()
                    .filter(x -> x.getId() == id)
                    .findFirst().orElse(null);
            if (u == null) {
                error = true;
                mensaje = "Usuario a editar no encontrado.";
            } else {
                esEdicion = true;
            }
        } catch (NumberFormatException e) {
            error = true;
            mensaje = "ID de usuario inválido.";
        }
    }

    if (!error) {
        if (!esEdicion && (contrasena == null || contrasena.trim().isEmpty())) {
            error = true;
            mensaje = "La contraseña es obligatoria para crear usuario.";
        }
    }

    if (!error) {
        if (!esEdicion) {
            u = new Usuario();
        }
        u.setNombre(nombre.trim());
        u.setUsuario(usuarioParam.trim());
        if (contrasena != null && !contrasena.trim().isEmpty()) {
            u.setContraseña(contrasena);
        }
        try {
            int rolId = Integer.parseInt(rolParam);
            Rol rolObj = Rol.findById(rolId);
            if (rolObj == null) {
                throw new Exception("No existe rol con ID " + rolId);
            }
            u.setRol(rolObj);
        } catch (Exception e) {
            error = true;
            mensaje = "Rol inválido.";
        }
    }

    if (!error) {
        if (areaParam != null && !areaParam.trim().isEmpty()) {
            try {
                int areaId = Integer.parseInt(areaParam.trim());
                u.setIdArea(areaId);
            } catch (NumberFormatException e) {
                u.setIdArea(null);
            }
        } else {
            u.setIdArea(null);
        }
    }

    if (!error) {
        Usuario existente = Usuario.findAll().stream()
                .filter(x -> x.getUsuario().equalsIgnoreCase(usuarioParam.trim()))
                .findFirst().orElse(null);
        if (existente != null) {
            if (!esEdicion || existente.getId() != u.getId()) {
                error = true;
                mensaje = "El nombre de usuario ya está en uso.";
            }
        }
    }

    if (!error) {
        try {
            u.saveOrUpdate();
            mensaje = esEdicion ? "Usuario actualizado correctamente." : "Usuario agregado correctamente.";
        } catch (Exception ex) {
            error = true;
            mensaje = "Error al guardar en la base de datos: " + ex.getMessage();
        }
    }

    String destino = "usuario.jsp";
    if (mensaje != null) {
        destino += "?msg=" + URLEncoder.encode(mensaje, "UTF-8");
        if (error) {
            destino += "&error=1";
        }
    }
    response.sendRedirect(destino);
%>
