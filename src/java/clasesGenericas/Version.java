package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class Version {
    private int id;
    private int docId;
    private int numero;
    private Timestamp timestamp;
    private String ruta;

    public Version() { }

    public Version(int id, int docId, int numero, Timestamp timestamp, String ruta) {
        this.id        = id;
        this.docId     = docId;
        this.numero    = numero;
        this.timestamp = timestamp;
        this.ruta      = ruta;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getDocId() {
        return docId;
    }

    public void setDocId(int docId) {
        this.docId = docId;
    }

    public int getNumero() {
        return numero;
    }

    public void setNumero(int numero) {
        this.numero = numero;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }

    public String getRuta() {
        return ruta;
    }

    public void setRuta(String ruta) {
        this.ruta = ruta;
    }


    public boolean save() {
        String sql = "INSERT INTO version(doc_id, numero, ruta) VALUES(?, ?, ?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, docId);
            ps.setInt(2, numero);
            ps.setString(3, ruta);
            if (ps.executeUpdate() == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        this.id = rs.getInt(1);
                    }
                }
                return true;
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean update() {
        String sql = "UPDATE version SET doc_id = ?, numero = ?, ruta = ? WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, docId);
            ps.setInt(2, numero);
            ps.setString(3, ruta);
            ps.setInt(4, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

 
    public boolean delete() {
        String sql = "DELETE FROM version WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public static List<Version> findAll() {
        List<Version> lista = new ArrayList<>();
        String sql = "SELECT id, doc_id, numero, timestamp, ruta FROM version";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Version(
                    rs.getInt("id"),
                    rs.getInt("doc_id"),
                    rs.getInt("numero"),
                    rs.getTimestamp("timestamp"),
                    rs.getString("ruta")
                ));
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }

    public static Version findById(int idBuscado) {
        String sql = "SELECT id, doc_id, numero, timestamp, ruta FROM version WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Version(
                        rs.getInt("id"),
                        rs.getInt("doc_id"),
                        rs.getInt("numero"),
                        rs.getTimestamp("timestamp"),
                        rs.getString("ruta")
                    );
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }

 
    public static List<Version> findByDocId(int documentoId) {
        List<Version> lista = new ArrayList<>();
        String sql = "SELECT id, doc_id, numero, timestamp, ruta FROM version WHERE doc_id = ? ORDER BY numero";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, documentoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new Version(
                        rs.getInt("id"),
                        rs.getInt("doc_id"),
                        rs.getInt("numero"),
                        rs.getTimestamp("timestamp"),
                        rs.getString("ruta")
                    ));
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }
}
