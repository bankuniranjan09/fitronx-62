
import React from 'react';
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";

interface WinnersDialogProps {
  winners: string[];
  showWinnersDialog: boolean;
  setShowWinnersDialog: (show: boolean) => void;
  onPickWinner: (e: React.MouseEvent) => void;
}

const WinnersDialog: React.FC<WinnersDialogProps> = ({
  winners,
  showWinnersDialog,
  setShowWinnersDialog,
  onPickWinner
}) => {
  return (
    <Dialog open={showWinnersDialog} onOpenChange={setShowWinnersDialog}>
      <DialogTrigger asChild>
        <Button 
          type="button"
          onClick={onPickWinner}
          className="flex-1 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white font-semibold py-3 px-6 rounded-lg transition-all duration-300 transform hover:scale-105"
        >
          Pick Winner
        </Button>
      </DialogTrigger>
      <DialogContent className="bg-gradient-to-br from-orange-900/90 to-red-900/90 backdrop-blur-lg border border-white/20 text-white">
        <DialogHeader>
          <DialogTitle className="text-center text-2xl">🏆 Winners List 🏆</DialogTitle>
          <DialogDescription className="text-center text-gray-300">
            Here are all the winners selected from today's participants!
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-3 max-h-60 overflow-y-auto">
          {winners.length === 0 ? (
            <p className="text-center text-gray-400">No winners yet! Click Pick Winner to select from today's participants.</p>
          ) : (
            winners.map((winner, index) => (
              <div key={index} className="bg-white/10 rounded-lg p-3 flex items-center justify-between">
                <span className="font-medium">#{index + 1}</span>
                <span className="text-sm flex-1 mx-3">{winner}</span>
                <span className="text-2xl">🎉</span>
              </div>
            ))
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default WinnersDialog;
