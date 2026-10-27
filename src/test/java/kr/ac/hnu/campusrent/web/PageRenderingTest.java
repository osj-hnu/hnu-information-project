package kr.ac.hnu.campusrent.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class PageRenderingTest {
    @Autowired MockMvc mvc;

    @Test void homeRendersTemplateAndLocalAssets() throws Exception {
        mvc.perform(get("/"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("공간과 장비를 찾아보세요.")))
            .andExpect(content().string(containsString("/purpose?activity=")))
            .andExpect(content().string(not(containsString("th:replace"))));
        mvc.perform(get("/assets/ff97a.svg")).andExpect(status().isOk())
            .andExpect(content().string(containsString("<svg")));
        mvc.perform(get("/css/campusrent.css")).andExpect(status().isOk());
        mvc.perform(get("/js/home.js")).andExpect(status().isOk());
    }

    @Test void searchFiltersTheCorrectResourceKind() throws Exception {
        mvc.perform(get("/equipment").param("q", "카메라"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("2개 항목")))
            .andExpect(content().string(containsString("DEMO-CAM100")))
            .andExpect(content().string(not(containsString("DEMO-MIC100"))));
        mvc.perform(get("/facilities").param("q", "회의실"))
            .andExpect(status().isOk()).andExpect(content().string(containsString("2개 항목")));
    }

    @Test void emptySearchAndUntrustedInputAreHandled() throws Exception {
        mvc.perform(get("/equipment").param("q", "없는 장비"))
            .andExpect(status().isOk()).andExpect(content().string(containsString("검색 결과가 없습니다.")));
        mvc.perform(get("/purpose").param("activity", "<script>alert(1)</script>"))
            .andExpect(status().isOk())
            .andExpect(content().string(containsString("&lt;script&gt;")))
            .andExpect(content().string(not(containsString("<script>alert(1)</script>"))));
    }
}
