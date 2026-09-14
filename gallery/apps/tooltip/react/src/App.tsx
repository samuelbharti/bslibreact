import { Card, CardHeader, CardBody, PageFillable, Tooltip } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Tooltip</CardHeader>
        <CardBody>
          <Tooltip text="Extra detail on hover">
            <span style={{ cursor: "help", textDecoration: "underline dotted" }}>
              Hover for info
            </span>
          </Tooltip>
        </CardBody>
      </Card>
    </PageFillable>
  );
}
