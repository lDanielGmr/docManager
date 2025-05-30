package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class AuditLog {
    private int id;
    private int usuarioId;
    private int documentoId;
    private String accion;
    private Timestamp timestamp;

    public AuditLog() { }

    public AuditLog(int id, int usuarioId, int documentoId, String accion, Timestamp timestamp) {
        this.id = id;
        this.usuarioId = usuarioId;
        this.documentoId = documentoId;
        this.accion = accion;
        this.timestamp = timestamp;
    }


    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(int usuarioId) {
        this.usuarioId = usuarioId;
    }

    public int getDocumentoId() {
        return documentoId;
    }

    public void setDocumentoId(int documentoId) {
        this.documentoId = documentoId;
    }

    public String getAccion() {
        return accion;
    }

    public void setAccion(String accion) {
        this.accion = accion;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }


    public static boolean log(int usuarioId, int documentoId, String accion) {
        String sql = "INSERT INTO audit_log(usuario_id, documento_id, accion) VALUES(?,?,?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            ps.setInt(2, documentoId);
            ps.setString(3, accion);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }


    public static List<AuditLog> findAll() {
        List<AuditLog> lista = new ArrayList<>();
        String sql = "SELECT id, usuario_id, documento_id, accion, timestamp FROM audit_log";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                AuditLog a = new AuditLog(
                    rs.getInt("id"),
                    rs.getInt("usuario_id"),
                    rs.getInt("documento_id"),
                    rs.getString("accion"),
                    rs.getTimestamp("timestamp")
                );
                lista.add(a);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lista;
    }
}
