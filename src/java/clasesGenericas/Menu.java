package clasesGenericas;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

public class Menu {
    private static final Map<Integer, Map<String, Integer>> usageByUser = new ConcurrentHashMap<>();

    private static final Map<String, String> labels = Map.ofEntries(
        Map.entry("inicio.jsp",             "Inicio"),
        Map.entry("documento.jsp",          "Documentos"),
        Map.entry("documentoPlantilla.jsp", "Plantillas"),
        Map.entry("buscarDocumento.jsp",    "Búsquedas"),
        Map.entry("versionDocumento.jsp",   "Versiones"),
        Map.entry("papelera.jsp",           "Papelera"),
        Map.entry("auditoria.jsp",          "Auditoría"),
        Map.entry("usuario.jsp",            "Usuarios"),
        Map.entry("rol.jsp",                "Roles"),
        Map.entry("etiqueta.jsp",           "Etiquetas"),
        Map.entry("permiso.jsp",            "Permisos"),
        Map.entry("preferencia.jsp",        "Preferencias")
    );

 
    public static void recordUse(int userId, String url) {
        if (!labels.containsKey(url)) {
            return;
        }
        Map<String, Integer> userMap = usageByUser.computeIfAbsent(userId, k -> new ConcurrentHashMap<>());
        userMap.merge(url, 1, Integer::sum);
    }


    public static List<Map<String, String>> findTopShortcutsByUser(int userId) {
        Map<String, Integer> userMap = usageByUser.get(userId);
        if (userMap == null || userMap.isEmpty()) {
            return Collections.emptyList();
        }

        return userMap.entrySet().stream()
            .filter(e -> e.getValue() > 0)
            .sorted((e1, e2) -> Integer.compare(e2.getValue(), e1.getValue()))
            .limit(4)
            .map(entry -> {
                String url   = entry.getKey();
                String label = labels.get(url);
                Map<String, String> m = new HashMap<>();
                m.put("url",   url);
                m.put("label", label);
                return m;
            })
            .collect(Collectors.toList());
    }

  
    public static List<Map<String, String>> findTopShortcuts() {
        Map<String, Integer> globalCounts = new HashMap<>();
        for (Map<String, Integer> userMap : usageByUser.values()) {
            for (Map.Entry<String, Integer> e : userMap.entrySet()) {
                globalCounts.merge(e.getKey(), e.getValue(), Integer::sum);
            }
        }
        return globalCounts.entrySet().stream()
            .filter(entry -> entry.getValue() > 0)
            .sorted((e1, e2) -> Integer.compare(e2.getValue(), e1.getValue()))
            .limit(4)
            .map(entry -> {
                String url = entry.getKey();
                String label = labels.get(url);
                Map<String, String> m = new HashMap<>();
                m.put("url",   url);
                m.put("label", label);
                return m;
            })
            .collect(Collectors.toList());
    }
}
