<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.util.List,
    java.util.Set,
    java.util.stream.Collectors,
    clasesGenericas.Documento,
    clasesGenericas.Etiqueta,
    clasesGenericas.Usuario
" %>
<%
    Usuario user = (Usuario) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }

    String origin = request.getParameter("origin");
    boolean fromPlantilla = "plantilla".equals(origin);

    String idStr = request.getParameter("id");
    if (idStr == null) {
        out.println("<p style='color:red;'>Falta el parámetro id</p>");
        return;
    }
    int docId;
    try {
        docId = Integer.parseInt(idStr);
    } catch (NumberFormatException e) {
        out.println("<p style='color:red;'>ID inválido</p>");
        return;
    }

    Documento doc;
    try {
        doc = Documento.findById(docId);
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
    if (doc == null) {
        out.println("<p style='color:red;'>Documento no encontrado</p>");
        return;
    }

    List<Usuario> usuarios = Usuario.findAll();
    List<Etiqueta> etiquetasAll = Etiqueta.findAll();
    Set<Integer> etiquetasAsignadas = doc.getEtiquetaIds().stream().collect(Collectors.toSet());
    boolean esPlant = doc.isEsPlantilla();
    String numeroRadicadoActual = doc.getNumeroRadicado();
    if (numeroRadicadoActual == null) numeroRadicadoActual = "";
    Integer radicadoACurr = doc.getRadicadoA(); 
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Editar Documento</title>
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/fontawesome.css">
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/style.css">
  <link rel="icon" href="<%=request.getContextPath()%>/images/favicon.ico" type="image/x-icon" />
  <style>
    :root {
      --accent: #007bff;
      --text: #333;
      --light: #fff;
      --radius: 6px;
      --font: 'Poppins', sans-serif;
    }
    *, *::before, *::after { box-sizing: border-box; }
    body {
      font-family: var(--font);
      color: var(--text);
      margin: 0; padding: 20px;
      background: url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center center fixed;
      background-size: cover;
    }
    .editor-container {
      max-width: 600px; margin: auto;
      background: var(--light);
      padding: 24px; border-radius: var(--radius);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    h2 { margin-top: 0; color: #333; }
    .form-group { margin-bottom: 16px; }
    label { display: block; margin-bottom: 4px; font-weight: 500; }
    input[type="text"], select, input[type="file"] {
      width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px;
      font-size: .95rem;
    }
    input[type="text"][disabled] { background: #e9ecef; }
    input[type="checkbox"] { margin-right: 8px; }
    .inline { display: flex; align-items: center; gap: 8px; }
    .btn { padding: 8px 16px; border: none; border-radius: 4px;
           cursor: pointer; font-size: .95rem; }
    .btn-primary { background: var(--accent); color: var(--light); }
    .btn-secondary { background: #ccc; color: #333; }
    .file-current { margin-left: 8px; font-style: italic; }
    .disabled-label { color: #999; }
  </style>
</head>
<body>
  <div class="editor-container">
    <h2><i class="fas fa-edit"></i> Editar Documento</h2>

    <form action="guardarDocumento.jsp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="id" value="<%=doc.getId()%>"/>
      <% if (fromPlantilla || esPlant) { %>
        <input type="hidden" name="origin" value="plantilla" />
      <% } %>

      <input type="hidden" id="hiddenNumeroRadicado" name="numero_radicado" value="<%= esPlant ? "N/A" : numeroRadicadoActual %>"/>

      <div class="form-group">
        <label for="numeroRadicadoVisible">Número de Radicado:</label>
        <input type="text"
               id="numeroRadicadoVisible"
               placeholder="<%= esPlant ? "(No aplicable para plantilla)" : "Ingrese número de radicado" %>"
               value="<%= esPlant ? "N/A" : numeroRadicadoActual %>"
               <%= esPlant ? "disabled" : "required" %> />
      </div>

      <div class="form-group inline">
        <label>Archivo actual:</label>
        <span class="file-current"><%= doc.getNombreArchivo() != null ? doc.getNombreArchivo() : "—" %></span>
      </div>
      <div class="form-group inline">
        <label for="file">Archivo nuevo:</label>
        <input type="file" id="file" name="file"/>
      </div>

      <div class="form-group">
        <label for="titulo">Título:</label>
        <input type="text" id="titulo" name="titulo" required
               value="<%=doc.getTitulo()%>"/>
      </div>

      <div class="form-group">
        <label for="tipo">Tipo:</label>
        <input type="text" id="tipo" name="tipo"
               value="<%=doc.getTipo()%>" placeholder="Escriba el tipo…"/>
      </div>

      <div class="form-group">
        <label for="area">Área:</label>
        <input type="text" id="area" name="area"
               value="<%= user.getArea() != null ? user.getArea() : "-" %>" disabled/>
      </div>

      <div class="form-group inline">
        <input type="checkbox" id="esPlantilla" name="esPlantilla" value="true"
               <%= esPlant ? "checked" : "" %> />
        <label for="esPlantilla">Es plantilla</label>
      </div>

      <div class="form-group inline">
        <label for="etqs">Etiquetas:</label>
        <select id="etqs" name="etiquetas" multiple size="4">
          <% for (Etiqueta et : etiquetasAll) { %>
            <option value="<%=et.getId()%>"
              <%= etiquetasAsignadas.contains(et.getId()) ? "selected" : "" %>>
              <%=et.getNombre()%>
            </option>
          <% } %>
        </select>
        <button type="button" class="btn btn-secondary"
                onclick="añadirEtiqueta()">Añadir etiqueta</button>
      </div>

      <div class="form-group">
        <label>Recibido por:</label>
        <input type="text" value="<%=user.getNombre()%>" disabled />
        <input type="hidden" name="recibidoPor" value="<%=user.getId()%>"/>
      </div>

      <div class="form-group">
        <label id="labelRadicadoA">Radicado a:</label>
        <input type="text"
               id="radicadoAText"
               value="No aplica"
               disabled
               class="disabled-label"
               style="<%= esPlant ? "" : "display:none;" %>" />

        <select id="radicadoASelect"
                name="radicadoA"
                <%= esPlant ? "style=\"display:none;\" disabled" : "" %>>
          <option value=""
            <%= (radicadoACurr == null) ? "selected" : "" %>>
            (N/A)
          </option>
          <% for (Usuario u : usuarios) {
               if (radicadoACurr != null && u.getId() == radicadoACurr) {
          %>
            <option value="<%=u.getId()%>" selected><%=u.getNombre()%></option>
          <%   } else { %>
            <option value="<%=u.getId()%>"><%=u.getNombre()%></option>
          <%   }
             } %>
        </select>
      </div>

      <div class="form-group inline">
        <button type="submit" id="submitBtn" class="btn btn-primary">
          <i class="fas <%= esPlant ? "fa-save" : "fa-paper-plane" %>"></i>
          <%= esPlant ? "Guardar" : "Enviar" %>
        </button>
        <button type="button" class="btn btn-secondary"
                onclick="history.back()">
          <i class="fas fa-times"></i> Cancelar
        </button>
      </div>
    </form>
  </div>

  <script>
    const chkPlant = document.getElementById('esPlantilla');
    const inputVisible = document.getElementById('numeroRadicadoVisible');
    const inputHidden = document.getElementById('hiddenNumeroRadicado');
    const selRadicado = document.getElementById('radicadoASelect');
    const txtRadicado = document.getElementById('radicadoAText');
    const lblRadicado = document.getElementById('labelRadicadoA');

    function ajustarInterfaz() {
      const esPlantilla = chkPlant.checked;

      if (esPlantilla) {
        inputVisible.value = "N/A";
        inputVisible.disabled = true;
        inputHidden.value = "N/A";

        selRadicado.style.display = 'none';
        selRadicado.disabled = true;

        txtRadicado.style.display = '';
        lblRadicado.innerText = 'Radicado a: No aplica';
      } else {
        inputVisible.disabled = false;
        if (inputHidden.value === "N/A") {
          inputVisible.value = "";
          inputHidden.value = "";
        } else {
          inputVisible.value = inputHidden.value;
        }

        selRadicado.style.display = '';
        selRadicado.disabled = false;

        txtRadicado.style.display = 'none';
        lblRadicado.innerText = 'Radicado a:';
      }

      if (esPlantilla) {
        inputVisible.removeAttribute('required');
      } else {
        inputVisible.setAttribute('required', '');
      }
    }

    inputVisible.addEventListener('input', function() {
      if (!chkPlant.checked) {
        inputHidden.value = inputVisible.value.trim();
      }
    });

    chkPlant.addEventListener('change', ajustarInterfaz);

    ajustarInterfaz();

    async function añadirEtiqueta() {
      const nombre = prompt('Nombre de la nueva etiqueta:');
      if (!nombre) return;
      try {
        const resp = await fetch('crearEtiqueta.jsp?nombre=' + encodeURIComponent(nombre));
        if (!resp.ok) throw new Error(await resp.text());
        const json = await resp.json();
        const sel = document.getElementById('etqs');
        const opt = document.createElement('option');
        opt.value = json.id;
        opt.textContent = json.nombre;
        opt.selected = true;
        sel.appendChild(opt);
      } catch (err) {
        alert('Error al crear etiqueta: ' + err.message);
      }
    }
  </script>
</body>
</html>
