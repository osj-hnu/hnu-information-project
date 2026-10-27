package kr.ac.hnu.campusrent.web;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import java.util.List;

@Controller
public class HomeController {
    @GetMapping("/")
    public String home(@RequestParam(defaultValue = "") String activity, Model model) {
        model.addAttribute("activity", activity);
        model.addAttribute("keywords", List.of("인터뷰 촬영", "발표 연습", "팀 회의", "과제 영상 촬영", "기타"));
        return "home";
    }
}
