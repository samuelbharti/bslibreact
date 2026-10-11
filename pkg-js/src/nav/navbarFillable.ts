import { createContext } from "react";

// PageNavbar's own `fillable`, so a TabPane inside it defaults to the same
// value. Internal: not exported from the package.
export const NavbarFillableContext = createContext(false);
