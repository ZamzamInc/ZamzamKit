//___FILEHEADER___

struct ___VARIABLE_productName:identifier___Presenter: ___VARIABLE_productName:identifier___Presentable {
    private(set) var model: ___VARIABLE_productName:identifier___Model
}

extension ___VARIABLE_productName:identifier___Presenter {
    func display(for response: ___VARIABLE_productName:identifier___API.FetchResponse) {
        
    }
}

extension ___VARIABLE_productName:identifier___Presenter {
    func display(error: ___VARIABLE_moduleName:identifier___Error) {
        model(\.error, ViewError(from: error))
    }
}