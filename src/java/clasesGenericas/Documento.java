package clasesGenericas;

import ConexionBD.conexionBD;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.sql.Types;


public class Documento {
    private int id;
    private String titulo;
    private String tipo;
    private Timestamp fechaCreacion;
    private boolean eliminado;
    private Integer recibidoPor;
    private Integer radicadoA;
    private boolean esPlantilla;
    private boolean requiereRespuesta;
    private String areaNombre;
    private Integer idArea;
    private List<Integer> etiquetaIds = new ArrayList<>();


    public Documento() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    

    public String getAreaNombre() {
        return areaNombre;
    }
    public void setAreaNombre(String areaNombre) {
        this.areaNombre = areaNombre;
    }
    
    private String nombreArchivo;
    public String getNombreArchivo() { return nombreArchivo; }
    public void setNombreArchivo(String na) { this.nombreArchivo = na; }

    public Integer getIdArea() { return idArea; }
    public void setIdArea(Integer idArea) { this.idArea = idArea; }
    
    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public Timestamp getFechaCreacion() { return fechaCreacion; }
    public void setFechaCreacion(Timestamp fechaCreacion) { this.fechaCreacion = fechaCreacion; }

    public boolean isEliminado() { return eliminado; }
    public void setEliminado(boolean eliminado) { this.eliminado = eliminado; }

    public Integer getRecibidoPor() { return recibidoPor; }
    public void setRecibidoPor(Integer recibidoPor) { this.recibidoPor = recibidoPor; }

    public Integer getRadicadoA() { return radicadoA; }
    public void setRadicadoA(Integer radicadoA) { this.radicadoA = radicadoA; }

    public boolean isEsPlantilla() { return esPlantilla; }
    public void setEsPlantilla(boolean esPlantilla) { this.esPlantilla = esPlantilla; }
    public boolean getEsPlantilla() { return esPlantilla; }

    public boolean isRequiereRespuesta() { return requiereRespuesta; }
    public void setRequiereRespuesta(boolean requiereRespuesta) { this.requiereRespuesta = requiereRespuesta; }
    public boolean getRequiereRespuesta() { return requiereRespuesta; }
    public List<Integer> getEtiquetaIds() { return etiquetaIds; }

    public static int countAll() throws SQLException {
        String sql = "SELECT COUNT(*) FROM documento";
        try (Connection c = conexionBD.conectar();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public static int countRequireResponse() throws SQLException {
        String sql = "SELECT COUNT(*) FROM documento WHERE requiere_respuesta = TRUE";
        try (Connection c = conexionBD.conectar();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public static Documento findById(int id) throws SQLException {
        String sql =
          "SELECT "
        + "  d.id, d.titulo, d.tipo, d.fecha_creacion, d.eliminado, "
        + "  d.recibido_por, d.radicado_a, d.es_plantilla, d.requiere_respuesta, "
        + "  d.nombre_archivo, "
        + "  d.id_area, "                     
        + "  a.nombre AS area_nombre "
        + "FROM documento d "
        + "LEFT JOIN area a ON d.id_area = a.id "
        + "WHERE d.id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Documento d = new Documento();
                d.setId(rs.getInt("id"));
                d.setTitulo(rs.getString("titulo"));
                d.setTipo(rs.getString("tipo"));
                d.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
                d.setEliminado(rs.getBoolean("eliminado"));
                d.setRecibidoPor((Integer) rs.getObject("recibido_por"));
                d.setRadicadoA((Integer) rs.getObject("radicado_a"));
                d.setEsPlantilla(rs.getBoolean("es_plantilla"));
                d.setRequiereRespuesta(rs.getBoolean("requiere_respuesta"));
                d.setNombreArchivo(rs.getString("nombre_archivo"));
                d.setIdArea((Integer) rs.getObject("id_area"));             
                d.setAreaNombre(rs.getString("area_nombre"));

                // Cargar etiquetas asociadas
                String sql2 = "SELECT etq_id FROM docu_etiqueta WHERE doc_id = ?";
                try (PreparedStatement ps2 = c.prepareStatement(sql2)) {
                    ps2.setInt(1, id);
                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            d.getEtiquetaIds().add(rs2.getInt("etq_id"));
                        }
                    }
                }
                return d;
            }
        }
    }

    public static List<Documento> findRequireResponse(int offset, int limit) throws SQLException {
        String sql =
          "SELECT "
        + "  d.id, "
        + "  d.titulo, "
        + "  d.tipo, "
        + "  d.id_area, "
        + "  d.recibido_por, "
        + "  d.radicado_a, "              
        + "  d.fecha_creacion, "
        + "  d.eliminado, "
        + "  d.es_plantilla, "
        + "  d.requiere_respuesta, "
        + "  a.nombre AS area_nombre "
        + "FROM documento d "
        + "LEFT JOIN area a ON d.id_area = a.id "
        + "WHERE d.requiere_respuesta = TRUE "
        + "ORDER BY d.fecha_creacion DESC "
        + "LIMIT ? OFFSET ?";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, offset);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public static List<Documento> findAllPlantillas() throws SQLException {
        String sql =
          "SELECT "
          + "  d.id, "
          + "  d.titulo, "
          + "  d.tipo, "
          + "  d.id_area, "
          + "  d.recibido_por, "
          + "  d.radicado_a, "                
          + "  d.fecha_creacion, "
          + "  d.eliminado, "
          + "  d.es_plantilla, "
          + "  d.requiere_respuesta, "
          + "  a.nombre AS area_nombre "
          + "FROM documento d "
          + "LEFT JOIN area a ON d.id_area = a.id "
          + "WHERE d.es_plantilla = TRUE "
          + "ORDER BY d.fecha_creacion DESC";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Documento d = mapRow(rs);
                d.setAreaNombre(rs.getString("area_nombre"));
                list.add(d);
            }
        }
        return list;
    }

    public static List<Documento> findAll() throws SQLException {
            String sql =
              "SELECT "
            + "  d.id, "
            + "  d.titulo, "
            + "  d.tipo, "
            + "  d.id_area, "
            + "  d.recibido_por, "
            + "  d.radicado_a, "                
            + "  d.fecha_creacion, "
            + "  d.eliminado, "
            + "  d.es_plantilla, "
            + "  d.requiere_respuesta, "
            + "  a.nombre AS area_nombre "
            + "FROM documento d "
            + "LEFT JOIN area a ON d.id_area = a.id "
            + "ORDER BY d.fecha_creacion DESC";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    public void save(List<Integer> etiquetasIds) throws SQLException {
        try (Connection c = conexionBD.conectar()) {
                String insertDoc =
                "INSERT INTO documento " +
                "(titulo, tipo, id_area, es_plantilla, recibido_por, radicado_a, requiere_respuesta) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = c.prepareStatement(insertDoc, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, this.titulo);
                ps.setString(2, this.tipo);
                ps.setObject(3, this.idArea, Types.INTEGER);        
                ps.setBoolean(4, this.esPlantilla);
                ps.setObject(5, this.recibidoPor, Types.INTEGER);
                ps.setObject(6, this.radicadoA, Types.INTEGER);
                ps.setBoolean(7, this.requiereRespuesta);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) this.id = keys.getInt(1);
                    else throw new SQLException("No se generó ID para el documento.");
                }
            }
            insertarEtiquetas(etiquetasIds, c);
        }
    }

    public void save(List<Integer> etiquetasIds, int usuarioId) throws SQLException {
        try (Connection c = conexionBD.conectar()) {
            c.setAutoCommit(false);
            String insertDoc =
                  "INSERT INTO documento " +
                  "(titulo, tipo, id_area, es_plantilla, recibido_por, radicado_a, requiere_respuesta) " +
                  "VALUES (?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = c.prepareStatement(insertDoc, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, this.titulo);
                ps.setString(2, this.tipo);
                ps.setObject(3, this.idArea, Types.INTEGER);        
                ps.setBoolean(4, this.esPlantilla);
                ps.setObject(5, this.recibidoPor, Types.INTEGER);
                ps.setObject(6, this.radicadoA, Types.INTEGER);
                ps.setBoolean(7, this.requiereRespuesta);
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) this.id = keys.getInt(1);
                    else throw new SQLException("No se generó ID para el documento.");
                }
            }
            insertarEtiquetas(etiquetasIds, c);
            String insertLog = "INSERT INTO audit_log (usuario_id, documento_id, accion) VALUES (?, ?, ?)";
            try (PreparedStatement logStmt = c.prepareStatement(insertLog)) {
                logStmt.setInt(1, usuarioId);
                logStmt.setInt(2, this.id);
                logStmt.setString(3, "CREAR_DOCUMENTO");
                logStmt.executeUpdate();
            }
            c.commit();
        }
    }

    private void insertarEtiquetas(List<Integer> etiquetasIds, Connection c) throws SQLException {
        if (etiquetasIds != null && !etiquetasIds.isEmpty()) {
            String insertEtq = "INSERT INTO docu_etiqueta (doc_id, etq_id) VALUES (?, ?)";
            try (PreparedStatement ps2 = c.prepareStatement(insertEtq)) {
                for (Integer etqId : etiquetasIds) {
                    ps2.setInt(1, this.id);
                    ps2.setInt(2, etqId);
                    ps2.addBatch();
                }
                ps2.executeBatch();
            }
        }
    }

    private static Documento mapRow(ResultSet rs) throws SQLException {
        Documento d = new Documento();
        d.setId(rs.getInt("id"));
        d.setTitulo(rs.getString("titulo"));
        d.setTipo(rs.getString("tipo"));
        d.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
        d.setEliminado(rs.getBoolean("eliminado"));
        d.setAreaNombre(rs.getString("area_nombre"));
        d.setRecibidoPor((Integer) rs.getObject("recibido_por"));
        d.setRadicadoA((Integer) rs.getObject("radicado_a"));
        d.setEsPlantilla(rs.getBoolean("es_plantilla"));
        d.setRequiereRespuesta(rs.getBoolean("requiere_respuesta"));
        d.setIdArea((Integer)rs.getObject("id_area"));
        d.setAreaNombre(rs.getString("area_nombre"));

        return d;
    }
}
