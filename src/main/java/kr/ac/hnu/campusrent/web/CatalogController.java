package kr.ac.hnu.campusrent.web;

import kr.ac.hnu.campusrent.catalog.CatalogService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class CatalogController {
    private final CatalogService catalog;
    public CatalogController(CatalogService catalog) { this.catalog = catalog; }

    @GetMapping("/equipment")
    public String equipment(@RequestParam(defaultValue = "") String q, Model model) {
        return listing("장비", q, model);
    }
    @GetMapping("/facilities")
    public String facilities(@RequestParam(defaultValue = "") String q, Model model) {
        return listing("시설", q, model);
    }
    private String listing(String kind, String q, Model model) {
        model.addAttribute("title", kind + " 대여");
        model.addAttribute("kind", kind);
        model.addAttribute("q", q);
        model.addAttribute("resources", catalog.search(kind, q));
        return "catalog";
    }
    @GetMapping("/purpose")
    public String purpose(@RequestParam(defaultValue = "") String activity, Model model) {
        model.addAttribute("activity", activity);
        return "purpose";
    }
}
