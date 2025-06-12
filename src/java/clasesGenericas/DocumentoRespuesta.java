package clasesGenericas;

import java.time.LocalDateTime;
import java.util.Objects;


public class DocumentoRespuesta {
    private int id;
    private int documentoId;
    private String archivoPath;
    private int uploadedBy;
    private LocalDateTime fechaSubida;

    public DocumentoRespuesta() {
    }

    public DocumentoRespuesta(int documentoId, String archivoPath, int uploadedBy) {
        this.documentoId = documentoId;
        this.archivoPath = archivoPath;
        this.uploadedBy  = uploadedBy;
    }

    public DocumentoRespuesta(int id, int documentoId, String archivoPath, int uploadedBy, LocalDateTime fechaSubida) {
        this.id           = id;
        this.documentoId  = documentoId;
        this.archivoPath  = archivoPath;
        this.uploadedBy   = uploadedBy;
        this.fechaSubida  = fechaSubida;
    }


    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getDocumentoId() {
        return documentoId;
    }

    public void setDocumentoId(int documentoId) {
        this.documentoId = documentoId;
    }

    public String getArchivoPath() {
        return archivoPath;
    }

    public void setArchivoPath(String archivoPath) {
        this.archivoPath = archivoPath;
    }

    public int getUploadedBy() {
        return uploadedBy;
    }

    public void setUploadedBy(int uploadedBy) {
        this.uploadedBy = uploadedBy;
    }

    public LocalDateTime getFechaSubida() {
        return fechaSubida;
    }

    public void setFechaSubida(LocalDateTime fechaSubida) {
        this.fechaSubida = fechaSubida;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof DocumentoRespuesta)) return false;
        DocumentoRespuesta that = (DocumentoRespuesta) o;
        return id == that.id &&
               documentoId == that.documentoId &&
               uploadedBy == that.uploadedBy &&
               Objects.equals(archivoPath, that.archivoPath) &&
               Objects.equals(fechaSubida, that.fechaSubida);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, documentoId, archivoPath, uploadedBy, fechaSubida);
    }

    @Override
    public String toString() {
        return "DocumentoRespuesta{" +
               "id=" + id +
               ", documentoId=" + documentoId +
               ", archivoPath='" + archivoPath + '\'' +
               ", uploadedBy=" + uploadedBy +
               ", fechaSubida=" + fechaSubida +
               '}';
    }
}
