<%@ page import="
         java.util.List,
         clasesGenericas.Usuario,
         clasesGenericas.Etiqueta
         " %>
<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%
    Usuario user = (Usuario) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    boolean plantillaMode = "true".equals(request.getParameter("plantilla"));
    List<Usuario> usuarios     = Usuario.findAll();
    List<Etiqueta> etiquetasList = Etiqueta.findAll();
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title><%= plantillaMode ? "Subir nueva plantilla" : "Subir nuevo documento"%></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/fontawesome.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="icon" href="${pageContext.request.contextPath}/images/favicon.ico" type="image/x-icon" />

    <style>
        :root{
            --bg:#12121c;
            --accent:#007bff;
            --text:#eaeaea;
            --shadow:rgba(0,0,0,.6);
        }
        html,body{
            margin:0;padding:0;height:100%;
            background:var(--bg) url('<%=request.getContextPath()%>/images/login-bg.jpg') no-repeat center/cover fixed;
            color:var(--text);
            overflow-y:auto;
        }
        *{box-sizing:border-box;font-family:"Poppins",sans-serif;}

        .container{
            max-width:400px;background:#fff;color:#000;
            margin:40px auto;padding:24px;border-radius:8px;
            box-shadow:0 6px 18px rgba(0,0,0,.3);
        }
        h2{margin:0 0 10px;color:#333;font-size:1.4rem;}
        .meta{font-size:.9rem;margin-bottom:20px;}

        .form-group{margin-bottom:16px;display:flex;flex-direction:column;}
        .form-group.inline{flex-direction:row;align-items:center;gap:8px;margin-bottom:8px;}
        label{font-size:.9rem;margin-bottom:4px;}
        input[type=text],select,input[type=file]{
            padding:8px 10px;font-size:.9rem;border:1px solid #ccc;border-radius:4px;
        }
        select[multiple]{height:110px;}
        input[disabled],select[disabled]{background:#f5f5f5;}
        input[type=checkbox]{margin-right:6px;}
        .disabled-label{opacity:.6;pointer-events:none;}

        .buttons{display:flex;justify-content:flex-end;}
        .btn{
            background:var(--accent);border:none;padding:10px 16px;
            color:#fff;border-radius:4px;font-size:.9rem;cursor:pointer;
            display:inline-flex;align-items:center;gap:6px;
            transition:background .3s ease;
        }
        .btn:hover{background:#0056b3;}

        #uploadOverlay,#successOverlay{
            position:fixed;inset:0;background:var(--shadow);
            display:none;align-items:center;justify-content:center;z-index:999;
        }
        .overlay-card{
            background:#fff;color:#000;border-radius:8px;
            padding:30px 26px;text-align:center;box-shadow:0 4px 12px rgba(0,0,0,.25);
            min-width:280px;max-width:320px;animation:scaleIn .25s ease-out;
        }
        @keyframes scaleIn{from{transform:scale(.8);opacity:0;}to{transform:scale(1);opacity:1;}}

        progress{width:100%;margin-top:16px;}

        .btn-ok{
            margin-top:22px;padding:8px 16px;border:none;
            background:#28a745;color:#fff;font-size:1rem;border-radius:4px;
            cursor:pointer;transition:opacity .3s;
        }
        .btn-ok:hover{opacity:.9;}
    </style>
</head>
<body>
<div class="container">
    <h2><i class="fas fa-upload"></i> <%= plantillaMode ? "Subir nueva plantilla" : "Subir nuevo documento"%></h2>
    <p class="meta">Recibido por: <strong><%= user.getNombre()%></strong></p>

    <form id="frmDoc" enctype="multipart/form-data">
        <input type="hidden" name="recibidoPor" value="<%= user.getId()%>"/>
        <input type="hidden" name="id_area"     value="<%= user.getIdArea() != null ? user.getIdArea() : ""%>"/>

        <div class="form-group">
            <label for="numeroRadicado">Número de radicado <span style="color:red">*</span></label>
            <input type="text" id="numeroRadicado" name="numero_radicado" required maxlength="50" placeholder="Ingrese numero de radicado">
        </div>

        <div class="form-group">
            <label for="titulo">Título <span style="color:red">*</span></label>
            <input type="text" id="titulo" name="titulo" required maxlength="255" placeholder="Ingrese un título">
        </div>

        <div class="form-group">
            <label for="tipo">Tipo</label>
            <input type="text" id="tipo" name="tipo" maxlength="100" placeholder="Tipo de documento">
        </div>

        <div class="form-group">
            <label>Área (su asignada)</label>
            <input type="text" value="<%= user.getArea()!=null ? user.getArea() : "-"%>" disabled>
        </div>

        <div class="form-group inline">
            <input type="checkbox" id="esPlantilla" name="esPlantilla" value="true"
                   <%= plantillaMode ? "checked onclick=\"return false;\"" : ""%>>
            <label for="esPlantilla" class="<%= plantillaMode ? "disabled-label" : ""%>">Es plantilla</label>
        </div>

        <div class="form-group inline">
            <input type="checkbox" id="requiereRespuesta" name="requiere_respuesta" value="true"
                   <%= plantillaMode ? "disabled" : ""%>>
            <label for="requiereRespuesta" class="<%= plantillaMode ? "disabled-label" : ""%>">Requiere respuesta</label>
        </div>

        <div class="form-group">
            <label for="radicadoA">Radicado a <span style="color:red">*</span></label>
            <select id="radicadoA" name="radicadoA" <%= plantillaMode ? "disabled" : ""%>>
                <option value="">-- Selecciona usuario --</option>
                <option value="NA">N/A</option>
                <% for(Usuario u:usuarios){ if(u.getId()==user.getId())continue;%>
                    <option value="<%=u.getId()%>"><%=u.getNombre()%></option>
                <%}%>
            </select>
        </div>

        <div class="form-group">
            <label for="etqs">Etiquetas (Ctrl+clic)</label>
            <select id="etqs" name="etiquetas" multiple size="5">
                <% for(Etiqueta e:etiquetasList){ %>
                    <option value="<%=e.getId()%>"><%=e.getNombre()%></option>
                <% } %>
            </select>
        </div>

        <div class="form-group">
            <label for="file">Archivo <span style="color:red">*</span></label>
            <input type="file" id="file" name="file" accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.png" required>
        </div>

        <div class="buttons">
            <button type="button" id="btnSubmit" class="btn">
                <i class="fas fa-save"></i> <span id="btnText"><%= plantillaMode ? "Guardar" : "Enviar"%></span>
            </button>
        </div>
    </form>
</div>

<div id="uploadOverlay">
    <div class="overlay-card">
        <p style="font-weight:600;font-size:1rem;margin:0 0 6px;">Guardando…</p>
        <progress id="uploadProgress" value="0" max="100"></progress>
    </div>
</div>

<div id="successOverlay">
    <div class="overlay-card">
        <p id="successMessage" style="font-weight:600;font-size:1rem;margin:0;"></p>
        <button class="btn-ok" onclick="closeSuccessOverlay()">OK</button>
    </div>
</div>

<script>
    const esPlantillaCheckbox = document.getElementById('esPlantilla'),
          selRad       = document.getElementById('radicadoA'),
          etqSelect    = document.getElementById('etqs'),
          btnSubmit    = document.getElementById('btnSubmit'),
          btnText      = document.getElementById('btnText'),
          uploadOv     = document.getElementById('uploadOverlay'),
          successOv    = document.getElementById('successOverlay'),
          successMsg   = document.getElementById('successMessage'),
          progressBar  = document.getElementById('uploadProgress');

    if(<%=plantillaMode%>){
        selRad.value='NA';selRad.disabled=true;
    }

    esPlantillaCheckbox.addEventListener('change',()=>{
        if(esPlantillaCheckbox.checked){
            selRad.value='NA';selRad.disabled=true;
            btnText.textContent='Guardar';
        }else{
            selRad.disabled=false;selRad.value='';
            btnText.textContent='Enviar';
        }
    });

    function closeSuccessOverlay(){successOv.style.display='none';}

    btnSubmit.addEventListener('click',()=>{
        const numeroRad=document.getElementById('numeroRadicado').value.trim(),
              tituloVal=document.getElementById('titulo').value.trim(),
              fileInput=document.getElementById('file');

        if(!numeroRad){alert('El campo "Número de radicado" es obligatorio.');return;}
        if(!tituloVal){alert('El campo "Título" es obligatorio.');return;}
        if(fileInput.files.length===0){alert('Debes seleccionar un archivo.');return;}

        const fd=new FormData();
        fd.append('recibidoPor','<%=user.getId()%>');
        fd.append('id_area','<%=user.getIdArea()!=null?user.getIdArea():""%>');
        fd.append('numero_radicado',numeroRad);
        fd.append('titulo',tituloVal);
        fd.append('tipo',document.getElementById('tipo').value||'');

        const isPlantilla=esPlantillaCheckbox.checked;
        fd.append('esPlantilla',isPlantilla);
        if(!isPlantilla){
            if(!selRad.value){alert('Debes seleccionar a quién va radicado.');return;}
            fd.append('radicadoA',selRad.value);
            if(document.getElementById('requiereRespuesta').checked){fd.append('requiere_respuesta','true');}
        }else{
            fd.append('radicadoA','NA');
        }

        const etqs=[...etqSelect.selectedOptions].map(o=>o.value);
        fd.append('etiquetas',etqs.join(','));
        fd.append('file',fileInput.files[0]);

        uploadOv.style.display='flex';progressBar.value=0;

        const xhr=new XMLHttpRequest();
        xhr.open('POST','guardarDocumento.jsp',true);

        xhr.upload.addEventListener('progress',e=>{
            if(e.lengthComputable){progressBar.value=(e.loaded/e.total)*100;}
        });

        xhr.addEventListener('load',()=>{
            uploadOv.style.display='none';
            successMsg.textContent=isPlantilla?'Plantilla guardada correctamente.':'Documento enviado correctamente.';
            successOv.style.display='flex';
        });

        xhr.send(fd);
    });
</script>
</body>
</html>
