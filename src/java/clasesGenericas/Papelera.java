package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class Papelera {
    private int id;
    private int docId;
    private Timestamp fechaElim;
    private String ubicOrigin;

    public Papelera() { }

    public Papelera(int id, int docId, Timestamp fechaElim, String ubicOrigin) {
        this.id         = id;
        this.docId      = docId;
        this.fechaElim  = fechaElim;
        this.ubicOrigin = ubicOrigin;
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

    public Timestamp getFechaElim() {
        return fechaElim;
    }

    public void setFechaElim(Timestamp fechaElim) {
        this.fechaElim = fechaElim;
    }

    public String getUbicOrigin() {
        return ubicOrigin;
    }

    public void setUbicOrigin(String ubicOrigin) {
        this.ubicOrigin = ubicOrigin;
    }


    public boolean save() {
        String sql = "INSERT INTO papelera(doc_id, ubic_origin) VALUES(?, ?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, docId);
            ps.setString(2, ubicOrigin);
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


    public boolean delete() {
        String sql = "DELETE FROM papelera WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }


    public static List<Papelera> findAll() {
        List<Papelera> lista = new ArrayList<>();
        String sql = "SELECT id, doc_id, fecha_elim, ubic_origin FROM papelera";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Papelera(
                    rs.getInt("id"),
                    rs.getInt("doc_id"),
                    rs.getTimestamp("fecha_elim"),
                    rs.getString("ubic_origin")
                ));
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }

 
    public static Papelera findById(int idBuscado) {
        String sql = "SELECT id, doc_id, fecha_elim, ubic_origin FROM papelera WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Papelera(
                        rs.getInt("id"),
                        rs.getInt("doc_id"),
                        rs.getTimestamp("fecha_elim"),
                        rs.getString("ubic_origin")
                    );
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }
}
