package com.example.writeflow

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import com.example.writeflow.presentation.WriteFlowApp
import com.example.writeflow.presentation.theme.WriteFlowTheme
import com.example.writeflow.presentation.viewmodel.WriteFlowViewModel
import org.koin.androidx.compose.koinViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            WriteFlowTheme {
                val viewModel = koinViewModel<WriteFlowViewModel>()
                val state by viewModel.uiState.collectAsState()

                WriteFlowApp(
                    state = state,
                    onScreenSelected = viewModel::selectScreen,
                    onDocumentTypeSelected = viewModel::selectDocumentType,
                    onAddDocumentType = viewModel::addDocumentType,
                    onUpdateDocumentType = viewModel::updateSelectedDocumentType,
                    onBatchModeChanged = viewModel::setBatchMode,
                    onScan = viewModel::scan,
                    onAddPage = viewModel::showHome,
                    onPreviewPageSelected = viewModel::selectPreviewPage,
                    onRecognizedTextChanged = viewModel::updateCurrentPageText,
                    onCleanText = viewModel::cleanCurrentPage,
                    onExportSelected = viewModel::selectExportType,
                    onSearchChanged = viewModel::searchLibrary,
                )
            }
        }
    }
}
