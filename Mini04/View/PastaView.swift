//
//  PastaView.swift
//  Mini04
//
//  Created by luis fontinelles on 18/03/24.
//

import SwiftUI
import SwiftData

struct PastaView: View {
    // VM
    @ObservedObject var folderVM: FoldersViewModel
    @State private var isModalPresented = true // Modal sempre será apresentado ao entrar na view
    
    // PERSISTENCIA
    @Environment(\.modelContext) private var modelContext
    
    // EDITAR NOME DA PASTA
    @State private var editedName: String = ""
    @State private var isShowingModal = false
    @State var filteredTrainings: [TreinoModel] = []
    @State private var selectedTraining: TreinoModel?
    @State private var selectedTrainingIndex: Int?
    var body: some View {
        NavigationStack {
            ZStack {
                // quando clicar no botao abre uma zstack sobre toda a pastaview, ou seja, a "modal"
                if isShowingModal {
                    HStack {
                        Spacer()
                        //botao de retornar uma view
                        Button {
                            if selectedTrainingIndex! < filteredTrainings.count - 1{
                                selectedTrainingIndex! += 1
                            }
//                            folderVM.folder.treinos
                        } label: {
                            Image(systemName: "chevron.backward.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)

                        }
                        .disabled(selectedTrainingIndex! == filteredTrainings.count - 1 ? true : false)
                        .buttonStyle(.plain)
                        .padding()
                        ZStack(alignment: .top) {
                            //sombra
                            Color.black
                                .frame(maxHeight: .infinity)
                                .frame(width: 800)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .offset(y:25)
                                .blur(radius: 3)
                            
                            TreinoView(folderVM: folderVM, trainingVM: TreinoViewModel(treino: filteredTrainings[selectedTrainingIndex!]), isShowingModal: $isShowingModal)
                                .frame(maxHeight: .infinity)
                                .frame(width: 800)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .offset(y:25)
                            
                        }
                        // botao de passar uma view
                        Button {
//                            print(selectedTrainingIndex)
//                            print(filteredTrainings.count)
                            if selectedTrainingIndex! > 0 {
                                selectedTrainingIndex! -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedTrainingIndex == 0  ? true : false)
                        .padding()
                        Spacer()
                    }
                    .zIndex(1)
                }
                
                
                
                VStack {
                    // infos da pasta
                    // NOME DA PASTA
                    HStack {
                        //TextField("Nome da pasta", text: $editedName)
                        Text(folderVM.folder.nome)
                            .font(.title)
                        Spacer()
                        Button("Salvar Alterações") {
                            saveChanges()
                        }
                    }
                    HStack {
                        HStack {
                            Image(systemName: "calendar")
                            Text("\(folderVM.folder.data)")
                        }
                        HStack {
                            Image(systemName: "video.badge.waveform.fill")
                            Text("\(folderVM.folder.treinos.count) Treinos")
                        }
                        HStack {
                            Image(systemName: "handbag.fill")
                            Text("Objetivo: \(folderVM.folder.objetivoApresentacao)")
                        }
                        Text("Tempo Desejado: \(folderVM.folder.tempoDesejado)")
                    }
                    HStack {
                        ExpandableView(thumbnail: ThumbnailView(content: {
                            TimeFeedBackView(avaregeTime: folderVM.formatedAvareTime, wishTime: Double(folderVM.folder.tempoDesejado), treinos: folderVM.folder.treinos)
                        }), expanded: ExpandedView(content: {
                            TimeFeedBackViewExpand(avaregeTime: folderVM.formatedAvareTime, wishTime: Double(folderVM.folder.tempoDesejado), treinos: folderVM.folder.treinos)
                        }))
                        WordRepetitionView(folderVM: folderVM)
                        //                    ExpandableView(thumbnail: ThumbnailView(content: {
                        //                        TimeFeedBackView(avaregeTime: folderVM.formatedAvareTime, wishTime: Double(folderVM.folder.tempoDesejado), treinos: folderVM.folder.treinos)
                        //                    }), expanded: ExpandedView(content: {
                        //                        WordRepetitionView(folderVM: folderVM)
                        //                    }))
                    }
                    
                    Spacer()
                    
                    if folderVM.folder.treinos.isEmpty {
                        Text("Adicione um treino para começar")
                    }
                    
                    Spacer()
                    
                    // ABRIR PARA COMEÇAR A GRAVAR UM TREINO PASSANDO A PASTA QUE ESTAMOS
                    NavigationLink {
                        RecordingVideoView(folderVM: folderVM)
                    } label: {
                        Text("Novo Treino")
                    }
                    // exibe todos os treinos
                    MyTrainingsView(folderVM: folderVM, filteredTrainings: $filteredTrainings, isShowingModal: $isShowingModal, selectedTraining: $selectedTraining, selectedTrainingIndex: $selectedTrainingIndex)
                }
                .blur(radius: isShowingModal ? 3 : 0)
                .disabled(isShowingModal ? true : false)
            }
        }
        .padding()
        .onTapGesture {
            if isShowingModal {
                isShowingModal.toggle()
            }
        }
        .onChange(of: folderVM.folder, { oldValue, newValue in
            folderVM.modelContext = modelContext
        })
        .onAppear {
            folderVM.modelContext = modelContext
            do {
                try folderVM.modelContext?.save()
            } catch {
                print("Nao salvou")
            }
            //editedName = folderVM.folder.nome
            folderVM.calculateAvarageTime()
        }
        .onChange(of: folderVM.folder) {
            // quando adicionar um novo treino atualiza o valor do tempo medio dos treinos
            folderVM.calculateAvarageTime()
        }
        .sheet(isPresented: $isModalPresented) {
            FolderInfoModalView(isModalPresented: $isModalPresented)
        }
    }
    // UPDATE Nome da pasta e seus treinos
    func saveChanges() {
        // Atualiza o nome da pasta
        //folderVM.folder.nome = editedName
        
        for training in folderVM.folder.treinos {
            if !training.changedTrainingName {
                if let index = folderVM.folder.treinos.firstIndex(where: { $0.id == training.id }) {
                    training.nome = "Treino \(index + 1)"
                }
            }
            
        }
    }

}

// MARK: - MODAL DE INFORMACOES
struct FolderInfoModalView: View {
    @Binding var isModalPresented: Bool
    var body: some View {
        VStack {
            Text("Instruções:")
                .font(.title)
                .padding()

            Text("pipipipi")
                .padding()

            Button("Fechar") {
                isModalPresented = false
            }
            .padding()
        }
    }
}


