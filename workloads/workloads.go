package workloads

import (
	"github.com/cloudfoundry-incubator/pat/context"
)

type WorkloadAdder interface {
	AddWorkloadStep(WorkloadStep)
}

type WorkloadStep struct {
	Name        string
	Fn          func(context context.Context) error
	Description string
}

type WorkloadList struct {
	Workloads []WorkloadStep
}

var restContext = NewRestWorkload()

func DefaultWorkloadList() *WorkloadList {
	return &WorkloadList{[]WorkloadStep{
		StepWithContext("rest:target", restContext.Target, "Sets the CF target"),
		StepWithContext("rest:login", restContext.Login, "Performs a login to the REST api. This option requires rest:target to be included in the list of workloads"),
		StepWithContext("rest:push", restContext.Push, "Pushes a simple Ruby application using the REST api. This option requires both rest:target and rest:login to be included in the list of workloads"),
		Step("gcf:push", Push, "Pushes a simple Ruby application using the CF command-line"),
		Step("gcf:generateAndPush", GenerateAndPush, "Generates and pushes a unique simple Ruby application using the CF command-line"),
		Step("gcf:spring", Spring, "Pushes Spring Music, configured by manifest, using the CF command-line"),
		Step("dummy", Dummy, "An empty workload that can be used when a CF environment is not available"),
		Step("dummyWithErrors", DummyWithErrors, "An empty workload that generates errors. This can be used when a CF environment is not available"),
	}}
}

func Step(name string, fn func() error, description string) WorkloadStep {
	return WorkloadStep{name, func(ctx context.Context) error { return fn() }, description}
}

func StepWithContext(name string, fn func(context.Context) error, description string) WorkloadStep {
	return WorkloadStep{name, fn, description}
}

func (self *WorkloadList) DescribeWorkloads(to WorkloadAdder) {
	for _, workload := range self.Workloads {
		to.AddWorkloadStep(workload)
	}
}
