import { Card, CardHeader, CardBody, PageFillable, Tooltip } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Tooltip</CardHeader>
        <CardBody>
          <Tooltip text="Extra detail on hover">
            <i className="fas fa-circle-info" role="presentation" aria-label="circle-info icon" />
          </Tooltip>
        </CardBody>
      </Card>
    </PageFillable>
  );
}
