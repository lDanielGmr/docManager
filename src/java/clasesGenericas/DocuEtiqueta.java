package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class DocuEtiqueta {
    private int docId;
    private int etqId;

    public DocuEtiqueta() { }

    public DocuEtiqueta(int docId, int etqId) {
        this.docId = docId;
        this.etqId = etqId;
    }

    public int getDocId() {
        return docId;
    }

    public void setDocId(int docId) {
        this.docId = docId;
    }

    public int getEtqId() {
        return etqId;
    }

    public void setEtqId(int etqId) {
        this.etqId = etqId;
    }

    public boolean save() {
        String sql = "INSERT INTO docu_etiqueta(doc_id, etq_id) VALUES(?, ?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, docId);
            ps.setInt(2, etqId);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean delete() {
        String sql = "DELETE FROM docu_etiqueta WHERE doc_id = ? AND etq_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, docId);
            ps.setInt(2, etqId);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public static List<DocuEtiqueta> findByDocId(int documentoId) {
        List<DocuEtiqueta> lista = new ArrayList<>();
        String sql = "SELECT doc_id, etq_id FROM docu_etiqueta WHERE doc_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, documentoId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new DocuEtiqueta(
                        rs.getInt("doc_id"),
                        rs.getInt("etq_id")
                    ));
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }

    public static List<DocuEtiqueta> findByEtqId(int etiquetaId) {
        List<DocuEtiqueta> lista = new ArrayList<>();
        String sql = "SELECT doc_id, etq_id FROM docu_etiqueta WHERE etq_id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, etiquetaId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new DocuEtiqueta(
                        rs.getInt("doc_id"),
                        rs.getInt("etq_id")
                    ));
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }
}
