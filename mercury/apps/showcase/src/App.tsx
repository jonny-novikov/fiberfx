import type { ComponentType } from "react";
import { Shell } from "./chrome/Shell";
import { useRoute } from "./store";
import type { Route } from "./store";

import { Overview } from "./pages/Overview";
import { Colors } from "./pages/foundations/Colors";
import { Typography } from "./pages/foundations/Typography";
import { Spacing } from "./pages/foundations/Spacing";
import { ButtonPage } from "./pages/components/ButtonPage";
import { InputPage } from "./pages/components/InputPage";
import { SelectionPage } from "./pages/components/SelectionPage";
import { ChipBadgePage } from "./pages/components/ChipBadgePage";
import { AvatarPage } from "./pages/components/AvatarPage";
import { AlertPage } from "./pages/components/AlertPage";
import { ProgressPage } from "./pages/components/ProgressPage";
import { TabsPage } from "./pages/components/TabsPage";
import { ModalPage } from "./pages/components/ModalPage";
import { TablePage } from "./pages/components/TablePage";
import { SignInPage } from "./pages/patterns/SignInPage";
import { DashboardPage } from "./pages/patterns/DashboardPage";

const PAGES: Record<Route, ComponentType> = {
  overview: Overview,
  "foundations/colors": Colors,
  "foundations/type": Typography,
  "foundations/spacing": Spacing,
  "components/button": ButtonPage,
  "components/input": InputPage,
  "components/selection": SelectionPage,
  "components/chip": ChipBadgePage,
  "components/avatar": AvatarPage,
  "components/alert": AlertPage,
  "components/progress": ProgressPage,
  "components/tabs": TabsPage,
  "components/modal": ModalPage,
  "components/table": TablePage,
  "patterns/forms": SignInPage,
  "patterns/dashboard": DashboardPage,
};

export function App() {
  const route = useRoute();
  const Active = PAGES[route] ?? Overview;
  return (
    <Shell>
      <Active />
    </Shell>
  );
}
